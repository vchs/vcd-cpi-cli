source 'https://rubygems.org'
gemspec

['SDK_PATH', 'CPI_PATH'].each do |var|
  next unless ENV[var]
  filename = File.join ENV[var], 'Gemfile'
  eval File.read(filename), nil, filename
end