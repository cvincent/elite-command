require 'yaml'

class OrbitedConfigGenerator < Rails::Generator::Base
  def initialize(runtime_args, runtime_options={})
    super
    env = @args[0] || 'development' 
    @config = YAML.load_file(File.join(RAILS_ROOT, 'config', 'orbited.yml'))[env]
    @config.symbolize_keys!
    defaults
  end
  
  def defaults
    @config[:host] ||= 'localhost'
    @config[:port] ||= 8000
    @config[:ssl_host] ||= @config[:host]
    @config[:ssl_port] ||= @config[:port]
    @config[:stomp_host] ||= @config[:host]
    @config[:stomp_port] ||= 61613
    @config[:stomp_user] ||= ''
    @config[:stomp_password] ||= ''
  end
  
  def manifest
    record do |m|
      m.template 'orbited.cfg', 'config/orbited.cfg', :assigns => {:config => @config}
    end
  end
end
