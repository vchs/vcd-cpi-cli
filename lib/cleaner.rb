module VCloud
  class Cleaner
    def initialize(cpi)
      @cpi = cpi
    end

    def run(owner)
      puts "Cleaning for owner #{owner}"

      clean_entities owner, 'application/vnd.vmware.vcloud.vApp+xml' do |vapp|
        if vapp.vms
          vapp.vms.each do |vm|
            poweroff vm
          end
        end
        poweroff vapp
      end

      ['application/vnd.vmware.vcloud.media+xml',
       'application/vnd.vmware.vcloud.disk+xml',
       'application/vnd.vmware.vcloud.vAppTemplate+xml'].each do |type|
        clean_entities owner, type
      end
    end

    private

    def client
      @cpi.instance_eval { @delegate.instance_eval { client } }
    end

    def error_ignored
      yield
    rescue => ex
      puts "Ignored #{ex}"
    end

    def clean_entities(owner, type, &block)
      (client.vdc.get_nodes('ResourceEntity', { 'type' => type }) || []).each do |entity|
        error_ignored do
          object = client.resolve_link entity
          users = object.get_nodes('User', { 'type' => 'application/vnd.vmware.admin.user+xml' }) || []
          user = users[0]
          if user && user.name == owner
            block.call(object) if block
            link = object.get_nodes('Link', {'rel' => 'remove'}, true).first
            if link.nil? || link.href.to_s.nil?
              link = VCloudSdk::Xml::WrapperFactory.create_instance 'Link'
              link.rel  = "remove"
              link.type = ""
              link.href = object.href
            end
            puts "Deleting #{object.name}(#{object.urn}) of #{type}"
            client.invoke_and_wait :delete, link
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
        raise "#{object.name} unable to power off" unless poweroff_link
        client.invoke_and_wait :post, poweroff_link
        object = client.reload object
      end
      if object['deployed'] == 'true'
        puts "Undeploying #{object.name}"
        link = object.undeploy_link
        raise "#{object.name} can't be undeployed" unless link
        params = VCloudSdk::Xml::WrapperFactory.create_instance 'UndeployVAppParams'
        client.invoke_and_wait :post, link, :payload => params
      end
      object
    end
  end
end
