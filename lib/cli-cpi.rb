require 'thor'
require 'cloud'
require 'cloud/vcloud'
require_relative 'utils'

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
    
    desc 'delete-stemcell VAPPID', 'Delete specified vApp template'
    def delete_stemcell (vapp_id)
      cpi.delete_stemcell vapp_id
    end
    
    desc 'create-vm AGENTID VAPPID', 'Create a virtual machine inside the vApp'
    option :cpu, :default => 1, :type => :numeric, :desc => 'CPU number'
    option :mem, :required => true, :type => :numeric, :desc => 'Memory size in MB'
    option :disk, :required => true, :type => :numeric, :desc => 'Disk size in MB'
    option :env, :type => :hash, :default => {}, :desc => 'Environments'
    option :networks, :type => :array, :default => [], :desc => 'Networks'
    option :'disk-locality', :desc => 'Disk locality'
    def create_vm (agent_id, vapp_id)
      result = cpi.create_vm agent_id, vapp_id, { 'cpu' => options[:cpu], 'mem' => options[:mem], 'disk' => options[:disk] }, options[:networks], options[:'disk-locality'], options[:env]
      puts result.inspect
    end
    
    desc 'delete-vm VAPPID', 'Delete a virtual machine'
    def delete_vm (vapp_id)
      cpi.delete_vm vapp_id
    end
    
    desc 'reboot-vm VAPPID', 'Reboot a vApp'
    def reboot_vm (vapp_id)
      cpi.reboot_vm vapp_id
    end
    
    desc 'configure-networks VAPPID NETWORK...', 'Configure networks'
    def configure_networks (vapp_id, *networks)
      cpi.configure_networks vapp_id, networks
    end
    
    desc 'create-disk SIZE', 'Create disk'
    option :locality
    def create_disk (size)
      result = cpi.create_disk size.to_i, options[:locality]
      puts result.inspect
    end

    desc 'delete-disk DISKID', 'Delete disk'
    def delete_disk (disk_id)
      cpi.delete_disk disk_id
    end
  
    desc 'attach-disk VAPPID DISKID', 'Attach disk to vApp'
    def attach_disk (vapp_id, disk_id)
      cpi.attach_disk vapp_id, disk_id
    end
    
    desc 'detach-disk VAPPID DISKID', 'Detach disk from vApp'
    def detach_disk (vapp_id, disk_id)
      cpi.detach_disk vapp_id, disk_id
    end
  
    desc 'get-disk-size DISKID', 'Get disk size'
    def get_disk_size (disk_id)
      puts cpi.get_disk_size(disk_id).inspect
    end
    
    private
    
    def cpi
      unless @cpi
        cfg = config
        @logger = setup_logger options
        Bosh::Clouds::Config.configure StubConfig.new(@logger)
        @cpi = Bosh::Clouds::VCloud.new(cfg)
      end
      @cpi
    end
  end
end