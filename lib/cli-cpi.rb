require 'thor'
require 'cloud/vcloud'
require_relative 'utils'

module VCloud
  class CpiCli < Thor
    include Utils
    
    desc 'create-stemcell IMAGEFILE', 'Create a vApp template from stemcell image'
    def create_stemcell (image_file)
      result = cpi.create_stemcell(image_file, nil)
      puts result.inspect
    end
    
    private
    
    def cpi
      unless @cpi
        cfg = config
        @cpi = Bosh::Clouds::VCloud.new(cfg)
      end
      @cpi
    end
  end
end