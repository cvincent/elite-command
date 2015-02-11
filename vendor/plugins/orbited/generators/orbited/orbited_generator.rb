class OrbitedGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'orbited.yml', 'config/orbited.yml'
    end
  end
end
