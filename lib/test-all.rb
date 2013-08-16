module VCloud
  class ConcurrentWork
    def initialize(index, template_id, cpi, conf)
      @index = index
      @template_id = template_id
      @resource_pool = conf['resource_pool']
      @vm = conf['vms'][index]
      @network = {}
      @network[conf['network']] = {
        'ip' => @vm['ip'],
        'cloud_properties' => {
          'name' => conf['network']
        }
      }
      @env = conf['env']
      @cpi = cpi
    end

    def perform
      puts "[#{@index}:#{Thread.current.object_id.to_s(16)}] create_vm(#{@vm['name']})"
      vm_id = @cpi.create_vm @vm['name'], @template_id, @resource_pool, @network, nil, @env
      puts "[#{@index}:#{Thread.current.object_id.to_s(16)}] >> #{vm_id}"
      puts "[#{@index}:#{Thread.current.object_id.to_s(16)}] delete_vm(#{vm_id})"
      @cpi.delete_vm vm_id
    end
  end

  class SimpleTest
    def initialize(cpi, cfg)
      @cpi = cpi
      @conf = cfg
    end

    def run(options)
      template_id = options[:template]
      unless template_id
        puts "create_stemcell(#{@conf['stemcell']})"
        template_id = @cpi.create_stemcell @conf['stemcell'], nil
        puts ">> #{template_id}"
      end
      unless options[:concurrent]
        puts "create_vm(#{@conf['vm']['name']}, ...)"
        vm_id = @cpi.create_vm @conf['vm']['name'], template_id, @conf['vm']['resource_pool'], @conf['vm']['networks'], @conf['vm']['disk-locality'], @conf['vm']['env']
        puts ">> #{vm_id}"
        puts "create_vm(#{@conf['vm']['name2']}, ...)"
        vm2_id = @cpi.create_vm @conf['vm']['name2'], template_id, @conf['vm']['resource_pool'], @conf['vm']['networks2'], @conf['vm']['disk-locality'], @conf['vm']['env']
        puts ">> #{vm2_id}"
        puts "has_vm?(#{vm_id}): #{@cpi.has_vm?(vm_id)}"
        puts "has_vm?(#{vm2_id}): #{@cpi.has_vm?(vm_id)}"
        puts "has_vm?(#{template_id}): #{@cpi.has_vm?(template_id)}"
        # reboot vm is skipped here
        puts "configure_networks(#{vm_id}, ...)"
        @cpi.configure_networks vm_id, @conf['vm']['new_networks']
        puts "create_disk(#{@conf['disk']['size']}, ...)"
        disk_id = @cpi.create_disk @conf['disk']['size'].to_i, nil
        puts ">> #{disk_id}"
        puts "attach_disk(#{vm_id}, #{disk_id})"
        @cpi.attach_disk vm_id, disk_id
        puts "detach_disk(#{vm_id}, #{disk_id})"
        @cpi.detach_disk vm_id, disk_id
        puts "get_disk_size_mb(#{disk_id}): #{@cpi.get_disk_size_mb(disk_id)}"
        puts "delete_disk(#{disk_id})"
        @cpi.delete_disk disk_id
        puts "delete_vm(#{vm_id})"
        @cpi.delete_vm vm_id
        puts "delete_vm(#{vm2_id})"
        @cpi.delete_vm vm2_id
      end
      unless options[:simple]
        concurrent_test template_id if @conf['concurrent'].is_a?(Hash)
      end
      unless options[:template]
        puts "delete_stemcell(#{template_id})"
        @cpi.delete_stemcell template_id
      end
    end

    private

    def concurrent_test(template_id)
      threads = []
      @conf['concurrent']['vms'].each_index do |n|
        work = ConcurrentWork.new n, template_id, @cpi, @conf['concurrent']
        thread = Thread.new { work.perform }
        threads << thread
      end
      threads.each { |thread| thread.join }
    end
  end
end
