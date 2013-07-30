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
    
    desc 'delete-stemcell TEMPLATEID', 'Delete specified vApp template'
    def delete_stemcell (id)
      cpi.delete_stemcell id
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
      result = cpi.create_vm agent_id, vapp_id, { 'cpu' => options[:cpu], 'ram' => options[:mem], 'disk' => options[:disk] }, bosh_nets, options[:'disk-locality'], options[:env]
      puts result.inspect
    end
    
    desc 'delete-vm VMID', 'Delete a virtual machine'
    def delete_vm (id)
      cpi.delete_vm id
    end
    
    desc 'reboot-vm VMID', 'Reboot a vApp'
    def reboot_vm (id)
      cpi.reboot_vm id
    end
    
    desc 'has-vm VMID', 'Check valiadity of VMID'
    def has_vm (id)
      result = cpi.has_vm? id
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
      cpi.configure_networks vm_id, bosh_nets
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
      cpi.attach_disk vm_id, disk_id
    end
    
    desc 'detach-disk VMID DISKID', 'Detach disk from vApp'
    def detach_disk (vm_id, disk_id)
      cpi.detach_disk vm_id, disk_id
    end
  
    desc 'get-disk-size DISKID', 'Get disk size'
    def get_disk_size (disk_id)
      puts cpi.get_disk_size_mb(disk_id).inspect
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
  end
end