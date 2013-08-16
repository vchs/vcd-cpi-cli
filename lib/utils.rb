require 'common/thread_formatter'
require 'yaml'
require 'logger'

module VCloud
  module Utils
    CONFIG_LINK = File.join(ENV['HOME'], '.vcd-cli-config')

    def setup_config (config_file)
      cfg = begin
        YAML.load_file config_file
      rescue => ex
        fatal "Unable to load config: #{ex.message}"
      end
      fullpath = File.absolute_path config_file
      FileUtils.ln_sf fullpath, CONFIG_LINK
    end

    def config
      return begin
          YAML.load_file CONFIG_LINK
      rescue => ex
          fatal 'Configuration not available, please use target to select one'
      end
    end

    def dump_config
      cfg = begin
        YAML.load_file CONFIG_LINK
      rescue => ex
        puts 'Not available, please use target to select a configuration file'
        exit
      end
      puts YAML.dump(cfg)
    end

    def setup_logger(options)
      logger = Logger.new(options[:logger] || 'vcd-cli.log')
      logger.formatter = ThreadFormatter.new
      logger
    end

    def fatal (msg)
      $stderr.puts msg
      exit 1
    end
  end
end
