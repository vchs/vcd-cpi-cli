require 'rest_client'

module VCloud
  class Cleaner
    def initialize(cpi)
      @cpi = cpi
    end

    def run(owner, catalog)
      puts "Cleaning for owner #{owner}"

      clean_entities owner, 'application/vnd.vmware.vcloud.vApp+xml' do |vapp|
        if vapp.vms
          vapp.vms.each do |vm|
            error_ignored { poweroff vm }
          end
        end
        error_ignored { poweroff vapp }
      end

      ['application/vnd.vmware.vcloud.media+xml',
       'application/vnd.vmware.vcloud.disk+xml',
       'application/vnd.vmware.vcloud.vAppTemplate+xml'].each do |type|
        clean_entities owner, type
      end

      clean_catalog catalog if catalog
    end

    private

    def client
      @cpi.instance_eval { @delegate.instance_eval { client } }
    end

    def error_ignored
      yield
    rescue RestClient::Exception => ex
      puts "RestClient exception: #{ex}: #{ex.response.body}"
    rescue => ex
      puts "Ignored #{ex}: #{ex.backtrace}"
    end

    def force_link(object, rel)
      link = object.get_nodes('Link', {'rel' => rel}, true).first
      if link.nil? || link.href.to_s.nil?
        link = VCloudSdk::Xml::WrapperFactory.create_instance 'Link'
        link.rel  = rel
        link.type = ""
        link.href = object.href
      end
      link
    end

    def clean_entities(owner, type, &block)
      (client.vdc.get_nodes('ResourceEntity', { 'type' => type }) || []).each do |entity|
        error_ignored do
          puts "Checking #{entity.name}: #{entity.href}"
          object = client.resolve_link entity
          users = object.get_nodes('User', { 'type' => 'application/vnd.vmware.admin.user+xml' }) || []
          user = users[0]
          puts "Object owner: #{user ? user.name : ''}"
          if user && user.name == owner
            block.call(object) if block
            puts "Deleting #{object.name}(#{object.urn}) of #{type}"
            client.invoke_and_wait :delete, force_link(object, 'remove')
          end
        end
      end
    end

    def poweroff(object)
      object = client.reload object
      if object['status'] == VCloudSdk::Xml::RESOURCE_ENTITY_STATUS[:SUSPENDED].to_s
        puts "Discarding suspend state of #{object.name}"
        client.invoke_and_wait :post, object.discard_state
        object = client.reload object
      end
      if object['status'] != VCloudSdk::Xml::RESOURCE_ENTITY_STATUS[:POWERED_OFF].to_s
        puts "Powering off #{object.name}"
        poweroff_link = object.power_off_link
        unless poweroff_link
          puts "#{object.name} unable to power off, forced"
          poweroff_link = force_link(object, 'power:powerOff')
        end
        client.invoke_and_wait :post, poweroff_link
        object = client.reload object
      end
      if object['deployed'] == 'true'
        puts "Undeploying #{object.name}"
        link = object.undeploy_link
        unless link
          puts "#{object.name} can't be undeployed, forced"
          link = force_link(object, 'undeploy')
        end
        params = VCloudSdk::Xml::WrapperFactory.create_instance 'UndeployVAppParams'
        client.invoke_and_wait :post, link, :payload => params
      end
      object
    end

    def clean_catalog(name)
      nodes = client.org.get_nodes 'Link', {'type' => 'application/vnd.vmware.vcloud.catalog+xml', 'name' => name}
      return if !nodes or nodes.empty?
      nodes.each do |catalog_link|
        error_ignored do
          catalog = client.resolve_link catalog_link
          catalog.catalog_items.each do |item_link|
            error_ignored do
              item = client.resolve_link item_link
              puts "Deleting Catalog Item #{item.name}(#{item.urn})"
              client.invoke_and_wait :delete, force_link(item, 'remove')
            end
          end
        end
      end
    end
  end
end
