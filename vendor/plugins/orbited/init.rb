require 'yaml'
require 'ostruct'

::OrbitedConfig = OpenStruct.new(YAML.load_file(File.join(Rails.root, 'config', 'orbited.yml'))[Rails.env])

ActionView::Base.send :include, OrbitedHelper

Orbited.set_defaults