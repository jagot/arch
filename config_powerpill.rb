require 'json'

config = nil
File.open('/etc/powerpill/powerpill.json', 'r') do |file|
  config = JSON.parse(file.read)
end

config['rsync']['db only'] = false
File.open('/tmp/mirrorlist.rsync.filtered', 'r') do |file|
  config['rsync']['servers'] = file.read.split
end

File.open('/etc/powerpill/powerpill.json', 'w') do |file|
  file.write JSON.pretty_generate(config)
end
