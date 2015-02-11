require 'autotest/restart'

Autotest.add_discovery { "rails" }
Autotest.add_discovery { "rspec2" }

Autotest.add_hook :initialize do |at|
  at.add_mapping(/^app\/game_commands\/(.*)\.rb/) do |f, _|
    "spec/game_commands/#{_[1]}_spec.rb"
  end
  
  at.add_mapping(/^spec\/game_commands\/(.*)_spec\.rb/) do |f, _|
    "spec/game_commands/#{_[1]}_spec.rb"
  end

  at.add_mapping(/^app\/achievements\/(.*)\.rb/) do |f, _|
    "spec/achievements/#{_[1]}_spec.rb"
  end
  
  at.add_mapping(/^spec\/achievements\/(.*)_spec\.rb/) do |f, _|
    "spec/achievements/#{_[1]}_spec.rb"
  end

  at.unit_diff = 'cat'
end

Autotest.add_hook :ran_command do |at|
  File.open('/tmp/autotest.txt', 'wb') do |f|
    f.write at.results.join.gsub( /\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/, '')
  end
end

