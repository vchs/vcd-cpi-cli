spec = Gem::Specification.new do |s| 
  s.name = 'vcd-cli'
  s.version = '0.0.1'
  s.author = 'Yisui Hu'
  s.email = 'yisuih@vmware.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'The CLI for testing ruby_vcloud_sdk and bosh_vcloud_cpi'
  s.files = %w(
bin/vcd-cli
lib/cli-api.rb
lib/utils.rb
  )
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'vcd-cli'
  s.add_runtime_dependency('thor','0.18.1')
end
