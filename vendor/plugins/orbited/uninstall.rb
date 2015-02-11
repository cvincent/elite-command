FileUtils.rm File.join(RAILS_ROOT, 'config', 'orbited.yml')
FileUtils.rm File.join(RAILS_ROOT, 'config', 'orbited.cfg')

puts "Make sure you manually remove any references to Orbited helpers" 
