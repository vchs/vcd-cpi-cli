module VCloud
  module Utils
    def fatal (msg)
      $stderr.puts msg
      exit 1
    end
  end
end
