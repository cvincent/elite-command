require 'fileutils'
RAILS_ROOT = '/Users/cvincent/code.isdangero.us/war/'

templates = File.join(File.dirname(__FILE__), 'generators', 'orbited', 'templates')
orbited = File.join('config', 'orbited.yml')
FileUtils.cp File.join(templates, 'orbited.yml'), File.join(RAILS_ROOT, orbited) unless File.exist?(File.join(RAILS_ROOT, orbited))