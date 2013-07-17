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
  
    desc 'catalog CATALOGNAME', 'Display Catalog'
    def catalog (name)
      cat = client.get_catalog name
      puts cat.inspect
    end
    
    desc 'vapp VAPPID', 'Display vApp info'
    def vapp (id)
      vapp = client.get_vapp id
      puts vapp.inspect
    end
    
    desc 'upload-template VAPPNAME OVFDIR', 'Upload a vApp template'
    def upload_template (vapp_name, ovf_directory)
      item = client.upload_vapp_template vapp_name, ovf_directory
      puts item.inspect
    end
    
    desc 'upload-media CATALOGNAME FILE', 'Upload a media file'
    option :'storage-profile', :aliases => :p
    option :'image-type', :aliases => :t, :default => 'iso'
    def upload_media (name, file)
      item = client.upload_catalog_media name, file, options[:'storage-profile'], options[:'image-type']
      puts item.inspect
    end
    
    desc 'delete-media', 'Delete media'
    def delete_media (name)
      client.delete_catalog_media name
    end
    
    desc 'insert-media', 'Insert media to virtual machine'
    def insert_media (vm_uri, media_name)
      client.insert_catalog_media vm_uri, media_name
    end
    
    desc 'eject-media', 'Eject media from virtual machine'
    def eject_media (vm_uri, media_name)
      client.eject_catalog_media vm_uri, media_name
    end
    
    desc 'delete-vapp', 'Delete vApp'
    def delete_vapp (vapp_id)
      client.delete_vapp client.get_vapp(vapp_id)
    end
    
    desc 'instantiate', 'Instantiate vApp from template'
    option :description, :aliases => :d
    option :'disk-locality', :aliases => :k
    def instantiate (template_id, vapp_name)
      result = client.instantiate_vapp_template template_id, vapp_name
      puts result.inspect
    end
    
    desc 'delete-network', 'Delete network'
    def delete_network (vapp_id, *network_names)
      client.delete_network(vapp_id, *network_names)
    end
    
    desc 'add-network', 'Add network'
    option :name, :aliases => :n
    option :'fence-mode', :aliases => :m, :default => 'BRIDGED'
    def add_network (vapp_id, network_uri, name, fence)
      client.add_network vapp_id, network_uri, options[:name], Xml::FENCE_MODES[options[:'fence-mode'].to_sym]
    end
    
    desc 'create-disk', 'Create an Independent disk'
    option :retries, :aliases => :r
    def create_disk (name, size)
      client.create_disk name, size.to_i
    end
    
    desc 'delete-disk', 'Delete a disk'
    def delete_disk (disk_uri)
      client.delete_disk disk_uri
    end
    
    desc 'attach-disk', 'Attach a disk to a virtual machine'
    def attach_disk (vm_uri, disk_uri)
      client.attach_disk disk_uri, vm_uri
    end
    
    desc 'detach-disk', 'Detach a disk from a virtual machine'
    def detach_disk (vm_uri, disk_uri)
      client.detach_disk disk_uri, vm_uri
    end
    
    desc 'disk', 'Display disk information'
    def disk (disk_id)
      info = client.get_disk disk_id
      puts info.inspect
    end
    
    desc 'poweron', 'Power on vApp'
    def poweron (vapp_uri)
      client.power_on_vapp vapp_uri
    end
    
    desc 'poweroff', 'Power off vApp'
    def poweroff (vapp_uri)
      client.power_off_vapp vapp_uri
    end
    
    desc 'reboot', 'Reboot vApp'
    def reboot (vapp_uri)
      client.reboot_vapp vapp_uri
    end
    
    desc 'discard-state', 'Discard vApp suspended state'
    def discard_state (vapp_uri)
      client.discard_suspended_state_vapp vapp_uri
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