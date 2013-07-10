require 'thor'
require 'yaml'
require 'ruby_vcloud_sdk'
require_relative 'utils'

module VCloud
  CONFIG_LINK = File.join(ENV['HOME'], '.vcd-cli-config')
  
  class ApiCli < Thor
    include Utils
    
    class_option :logger, :type => :string, :aliases => :l

    desc 'target config-file', 'Select vCloud Director'
    def target (config_file)
      cfg = begin
        YAML.load_file config_file
      rescue => ex
        fatal "Unable to load config: #{ex.message}"
      end
      fullpath = File.absolute_path config_file
      FileUtils.ln_sf fullpath, CONFIG_LINK
    end
    
    desc 'info', 'Show target info'
    def info
      cfg = begin
        YAML.load_file CONFIG_LINK
      rescue => ex
        puts 'Not available, please use target to select a configuration file'
        exit
      end
      puts YAML.dump(cfg)
    end
    
    desc 'vdc', 'Display Virtual Data Center'
    def vdc
      ovdc = client.get_ovdc
      puts ovdc.inspect
    end
    
    desc 'catalog', 'Display Catalog'
    def catalog (name)
      cat = client.get_catalog name
      puts cat.inspect
    end
    
    desc 'vapp', 'Display vApp info'
    def vapp (id)
      vapp = client.get_vapp id
      puts vapp.inspect
    end
    
    private
    
    def client
      unless @client
        cfg = begin
          YAML.load_file CONFIG_LINK
        rescue => ex
          fatal 'Configuration not available, please use target to select one'
        end
        @logger = Logger.new(options[:logger] || 'vcd-cli.log')
        VCloudSdk::Config.configure({ 'logger' => @logger })
        @client = VCloudSdk::Client.new cfg['api'], cfg['username'], cfg['password'], cfg['entities'], cfg['control']
      end
      @client
    end
  end
end