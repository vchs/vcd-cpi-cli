require 'thor'
require 'cloud'
require 'cloud/vcloud'
require_relative 'utils'
require_relative 'test-all'
require_relative 'cleaner'

module VCloud
  class StubConfig
    attr_reader :logger

    def initialize(logger)
      @logger = logger
    end

    def db
    end

    def uuid
    end

    def task_checkpoint
    end
  end

  class CpiCli < Thor
    include Utils

    desc 'create-stemcell IMAGEFILE', 'Create a vApp template from stemcell image'
    def create_stemcell (image_file)
      result = cpi.create_stemcell(image_file, nil)
      puts result.inspect
    end

    desc 'delete-stemcell TEMPLATEID', 'Delete specified vApp template'
    def delete_stemcell (id)
      cpi.delete_stemcell resolve_template_name(id)
    end

    desc 'create-vm AGENTID TEMPLATEID', 'Create a virtual machine inside the vApp'
    option :cpu, :default => 1, :type => :numeric, :desc => 'CPU number'
    option :mem, :required => true, :type => :numeric, :desc => 'Memory size in MB'
    option :disk, :required => true, :type => :numeric, :desc => 'Disk size in MB'
    option :env, :type => :hash, :default => {}, :desc => 'Environments'
    option :networks, :type => :hash, :default => {}, :desc => 'Networks name:ip name:ip ...'
    option :'disk-locality', :desc => 'Disk locality'
    def create_vm (agent_id, vapp_id)
      bosh_nets = {}
      options[:networks].each do |name, ip|
        bosh_nets[name] = {
          'ip' => ip,
          'cloud_properties' => {
            'name' => name
          }
        }
      end
      result = cpi.create_vm agent_id, resolve_template_name(vapp_id), { 'cpu' => options[:cpu], 'ram' => options[:mem], 'disk' => options[:disk] }, bosh_nets, options[:'disk-locality'], options[:env]
      puts result.inspect
    end

    desc 'delete-vm VMID', 'Delete a virtual machine'
    def delete_vm (id)
      cpi.delete_vm resolve_vm_name(id)
    end

    desc 'reboot-vm VMID', 'Reboot a vApp'
    def reboot_vm (id)
      cpi.reboot_vm resolve_vm_name(id)
    end

    desc 'has-vm VMID', 'Check valiadity of VMID'
    def has_vm (id)
      result = cpi.has_vm? resolve_vm_name(id)
      puts result.inspect
    end

    desc 'configure-networks VMID NETWORK...', 'Configure networks'
    def configure_networks (vm_id, *networks)
      bosh_nets = {}
      networks.each do |network|
        cfg = network.split ':'
        bosh_nets[cfg[0]] = {
          'ip' => cfg[1],
          'cloud_properties' => {
            'name' => cfg[0]
          }
        }
      end
      cpi.configure_networks resolve_vm_name(vm_id), bosh_nets
    end

    desc 'create-disk SIZE', 'Create disk'
    option :'disk-locality', :desc => 'Disk locality'
    def create_disk (size)
      result = cpi.create_disk size.to_i, options[:'disk-locality']
      puts result.inspect
    end

    desc 'delete-disk DISKID', 'Delete disk'
    def delete_disk (disk_id)
      cpi.delete_disk disk_id
    end

    desc 'attach-disk VMID DISKID', 'Attach disk to vApp'
    def attach_disk (vm_id, disk_id)
      cpi.attach_disk resolve_vm_name(vm_id), disk_id
    end

    desc 'detach-disk VMID DISKID', 'Detach disk from vApp'
    def detach_disk (vm_id, disk_id)
      cpi.detach_disk resolve_vm_name(vm_id), disk_id
    end

    desc 'get-disk-size DISKID', 'Get disk size'
    def get_disk_size (disk_id)
      puts cpi.get_disk_size_mb(disk_id).inspect
    end

    desc 'vms', 'List virtual machines'
    def vms
      vapps = client.vdc.get_nodes 'ResourceEntity', {'type' => 'application/vnd.vmware.vcloud.vApp+xml'}
      raise 'No vApp available' if !vapps or vapps.empty?
      vapp = vapps.each do |vapp_entity|
        vapp = client.resolve_link vapp_entity.href
        owners = vapp.get_nodes 'User', { 'type' => 'application/vnd.vmware.admin.user+xml' }
        puts <<-EOF
vApp: #{vapp.name}
  URN : #{vapp.urn}
  HREF: #{vapp.href}"
  STAT: #{vapp['status']}
  OWNR: #{resolve_owner(vapp)}
  VMS :
        EOF
        vapp.vms.each do |vm|
          puts <<-EOF
    VM: #{vm.name}
      URN : #{vm.urn}
      HREF: #{vm.href}
      STAT: #{vm['status']}
        EOF
        end
      end
    end

    desc 'catalogs', 'List catalogs'
    def catalogs
      catalogs = client.org.get_nodes 'Link', {'type' => 'application/vnd.vmware.vcloud.catalog+xml'}
      raise 'No catalog available' if !catalogs or catalogs.empty?
      catalog = catalogs.each do |catalog_link|
        catalog = nil
        begin
          catalog = client.resolve_link catalog_link
        rescue => ex
          puts "Ignoring #{ex}"
        end
        if catalog
          puts <<-EOF
Catalog: #{catalog.name}
  URN : #{catalog.urn}
  HREF: #{catalog.href}
  ITEMS:
          EOF
          catalog.catalog_items.each do |item_link|
            begin
              item = client.resolve_link item_link
              puts <<-EOF
    ITEM: #{item.name}
      URN : #{item.urn}
      HREF: #{item.href}
      OWNR: #{resolve_owner(item)}
              EOF
            rescue => ex
              puts "Ignoring #{ex}"
            end
          end
        end
      end
    end

    desc 'disks', 'List independent disks'
    def disks
      entities = client.vdc.disks || []
      entities.each do |disk_entity|
        disk = nil
        begin
          disk = client.resolve_link disk_entity
        rescue => ex
          puts "Ignoring #{ex}"
        end
        if disk
          puts <<-EOF
Disk: #{disk.name}
  URN : #{disk.urn}
  HREF: #{disk.href}
  OWNR: #{resolve_owner(disk)}
  SIZE: #{disk['size']}
  BUS : #{disk['busType']}
  SBUS: #{disk['busSubType']}
          EOF
        end
      end
    end

    desc 'test CONFIGFILE', 'Simple test cover all functions'
    option :template, :desc => 'Template Id'
    def test (configfile)
      cfg = YAML.load_file configfile
      SimpleTest.new(cpi, cfg).run options
    end

    desc 'clean OWNER', 'Delete objects belonging to OWNER'
    def clean (owner)
      Cleaner.new(cpi).run owner
    end

    private

    def cpi
      unless @cpi
        cfg = config
        @logger = setup_logger options
        Bosh::Clouds::Config.configure StubConfig.new(@logger)
        @cpi = Bosh::Clouds::VCloud.new({ "vcds" => [cfg], "agent" => {} })
      end
      @cpi
    end

    def client
      cpi.instance_eval { @delegate.instance_eval { client } }
    end

    def resolve_vapp_name(id)
      unless id.start_with?('urn:')
        vapp = client.vdc.get_vapp id
        raise "vApp #{id} not found" unless vapp
        id = vapp.urn
      end
      id
    end

    def resolve_vm_name(id)
      unless id.start_with?('urn:')
        vapps = client.vdc.get_nodes 'ResourceEntity', {'type' => 'application/vnd.vmware.vcloud.vApp+xml'}
        raise 'No vApp available' if !vapps or vapps.empty?
        vm = nil
        vapps.find do |vapp_entity|
          vapp = client.resolve_link vapp_entity.href
          vm = vapp.vm id
        end
        raise "VM #{id} not found" unless vm
        id = vm.urn
      end
      id
    end

    def resolve_template_name(id)
      unless id.start_with?('urn:')
        catalogs = client.org.get_nodes 'Link', {'type' => 'application/vnd.vmware.vcloud.catalog+xml'}
        raise 'No catalog available' if !catalogs or catalogs.empty?
        item = nil
        catalogs.find do |catalog_link|
          catalog = nil
          begin
            catalog = client.resolve_link catalog_link
          rescue => ex
            puts "Ignoring #{ex}"
          end
          item = catalog.catalog_items(id).first if catalog
          item
        end
        raise "Template #{id} not found" unless item
        item = client.resolve_link item.href
        id = item.urn
      end
      id
    end

    def resolve_owner(object, default_name = nil)
      owners = object.get_nodes 'User', { 'type' => 'application/vnd.vmware.admin.user+xml' }
      owners && owners.any? ? owners[0].name : default_name
    end
  end
end