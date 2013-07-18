require 'thor'
require 'ruby_vcloud_sdk'
require_relative 'utils'

module VCloud
  class ApiCli < Thor
    include Utils
    
    desc 'vdc', 'Display Virtual Data Center'
    def vdc
      ovdc = client.get_ovdc
      puts ovdc.inspect
    end
    
    desc 'disks', 'Display disks'
    def disks
      ovdc = client.get_ovdc
      puts ovdc.disks.inspect
    end

    desc 'networks', 'Display available networks'
    def networks
      ovdc = client.get_ovdc
      puts ovdc.available_networks.inspect
    end
    
    desc 'storage-profiles', 'Display storage profiles'
    def storage_profiles
      ovdc = client.get_ovdc
      puts ovdc.storage_profiles.inspect
    end
  
    desc 'templates NAME', 'Display vApp templates by name'
    def templates (name)
      puts client.get_ovdc().get_vapp_templates(name).inspect
    end
    
    desc 'catalog CATALOGNAME', 'Display Catalog'
    def catalog (name)
      cat = client.get_catalog name
      puts cat.inspect
    end
    
    desc 'vapp-id NAME', 'Display vApp by name'
    def vapp_id (name)
      ovdc = client.get_ovdc
      puts ovdc.get_vapp(name).inspect
    end
    
    desc 'vapp VAPPID', 'Display vApp info'
    def vapp (id)
      vapp = client.get_vapp id
      puts vapp.inspect
    end
    
    desc 'vms VAPPID', 'Display virtual machines'
    def vms (id)
      vapp = client.get_vapp id
      puts vapp.vms.inspect
    end
    
    desc 'vapp-networks VAPPID', 'Display network configurations'
    def vapp_networks (id)
      vapp = client.get_vapp id
      puts vapp.network_config_section.inspect
    end
    
    desc 'upload-template VAPPNAME OVFDIR', 'Upload a vApp template'
    def upload_template (vapp_name, ovf_directory)
      item = client.upload_vapp_template vapp_name, ovf_directory
      puts item.inspect
    end
    
    desc 'upload-media NAME FILE', 'Upload a media file'
    option :'storage-profile', :aliases => :p
    option :'image-type', :aliases => :t, :default => 'iso'
    def upload_media (name, file)
      item = client.upload_catalog_media name, file, options[:'storage-profile'], options[:'image-type']
      puts item.inspect
    end
    
    desc 'delete-media NAME', 'Delete media'
    def delete_media (name)
      client.delete_catalog_media name
    end
    
    desc 'insert-media VM-URI NAME', 'Insert media to virtual machine'
    def insert_media (vm_uri, media_name)
      client.insert_catalog_media vm_uri, media_name
    end
    
    desc 'eject-media VM-URI NAME', 'Eject media from virtual machine'
    def eject_media (vm_uri, media_name)
      client.eject_catalog_media vm_uri, media_name
    end
    
    desc 'delete-vapp VAPPID', 'Delete vApp'
    def delete_vapp (vapp_id)
      client.delete_vapp client.get_vapp(vapp_id)
    end
    
    desc 'instantiate TEMPLATEID VAPPNAME', 'Instantiate vApp from template'
    option :description, :aliases => :d
    option :'disk-locality', :aliases => :k, :type => :array, :default => []
    def instantiate (template_id, vapp_name)
      result = client.instantiate_vapp_template template_id, vapp_name, options[:description], options[:'disk-locality']
      puts result.inspect
    end
    
    desc 'delete-network VAPPID NETWORK-NAME...', 'Delete network'
    def delete_network (vapp_id, *network_names)
      vapp = client.get_vapp vapp_id
      client.delete_network(vapp, *network_names)
    end
    
    desc 'add-network VAPPID NETWORK-URI', 'Add network'
    option :name, :aliases => :n
    option :'fence-mode', :aliases => :m, :default => 'bridged'
    def add_network (vapp_id, network_uri)
      client.add_network vapp_id, network_uri, options[:name], options[:'fence-mode']
    end
    
    desc 'create-disk NAME SIZE', 'Create an Independent disk'
    option :retries, :aliases => :r
    def create_disk (name, size)
      client.create_disk name, size.to_i
    end
    
    desc 'delete-disk DISK-URI', 'Delete a disk'
    def delete_disk (disk_uri)
      client.delete_disk disk_uri
    end
    
    desc 'attach-disk VM-URI DISK-URI', 'Attach a disk to a virtual machine'
    def attach_disk (vm_uri, disk_uri)
      client.attach_disk disk_uri, vm_uri
    end
    
    desc 'detach-disk VM-URI DISK-URI', 'Detach a disk from a virtual machine'
    def detach_disk (vm_uri, disk_uri)
      client.detach_disk disk_uri, vm_uri
    end
    
    desc 'disk DISKID', 'Display disk information'
    def disk (disk_id)
      info = client.get_disk disk_id
      puts info.inspect
    end
    
    desc 'poweron VAPPID', 'Power on vApp'
    def poweron (id)
      client.power_on_vapp client.get_vapp(id)
    end
    
    desc 'poweroff VAPPID', 'Power off vApp'
    option :undeploy, :type => :boolean, :default => false
    def poweroff (id)
      client.power_off_vapp client.get_vapp(id), options[:undeploy]
    end
    
    desc 'reboot VAPPID', 'Reboot vApp'
    def reboot (id)
      client.reboot_vapp client.get_vapp(id)
    end
    
    desc 'discard-state VAPPID', 'Discard vApp suspended state'
    def discard_state (id)
      client.discard_suspended_state_vapp client.get_vapp(id)
    end

    desc 'poweron-vm VAPPID VM-NAME', 'Power on vApp'
    def poweron_vm (id, name)
      client.power_on_vm client.get_vapp(id).vm(name)
    end
    
    desc 'poweroff-vm VAPPID VM-NAME', 'Power off vApp'
    option :undeploy, :type => :boolean, :default => false
    def poweroff_vm (id, name)
      client.power_off_vm client.get_vapp(id).vm(name), options[:undeploy]
    end
    
    desc 'reboot-vm VAPPID VM-NAME', 'Reboot vApp'
    def reboot_vm (id, name)
      client.reboot_vm client.get_vapp(id).vm(name)
    end
    
    desc 'discard-state-vm VAPPID VM-NAME', 'Discard vApp suspended state'
    def discard_state_vm (id, name)
      client.discard_suspended_state_vm client.get_vapp(id).vm(name)
    end
    
    private
    
    def client
      unless @client
        cfg = config
        @logger = setup_logger options
        VCloudSdk::Config.configure({ 'logger' => @logger })
        @client = VCloudSdk::Client.new cfg['url'], cfg['user'], cfg['password'], cfg['entities'], cfg['control']
      end
      @client
    end
  end
end