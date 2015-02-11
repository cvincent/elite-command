rails_root = Rails.root || File.dirname(__FILE__) + '/../..'
rails_env  = Rails.env  || 'development'

resque_config = YAML.load_file(File.join(rails_root, '/config/resque.yml'))
Resque.redis = resque_config[rails_env]
