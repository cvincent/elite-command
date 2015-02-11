# main details
set :application, "elite_command"
role :web, "REDACTED"
role :app, "REDACTED"
role :db,  "REDACTED", :primary => true

# server details
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :deploy_to, "/var/www/ec"
set :deploy_via, :remote_cache
set :user, "ubuntu"
set :group, "www"
set :use_sudo, false

ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]

# repo details
set :scm, :git
set :scm_username, "cvincent"
set :repository, "git@github.com:cvincent/War.git"
set :branch, "master"
set :git_enable_submodules, 1

# runtime dependencies
depend :remote, :gem, "bundler", ">=1.0.0.rc.2"

# tasks
namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Restart Orbited"
  task :restart_orbited, :roles => :app do
    # run "sudo /sbin/initctl restart orbited"
  end

  desc "Restart Bluepill"
  task :restart_bluepill, :roles => :app do
    run "sudo bluepill stop"
    sleep 10
    run "sudo /etc/init.d/bluepill restart"
  end

  desc "Symlink shared resources on each release"
  task :symlink_shared, :roles => :app do
    #run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end

  desc 'Bundle and minify the JS and CSS files'
  task :bundle_assets, :roles => :app do
    root_path = File.expand_path(File.dirname(__FILE__) + '/..')
    assets_path = "#{root_path}/public/assets"
    gem_path = ENV['GEM_HOME']
    run_locally "#{gem_path}/bin/jammit"
    top.upload assets_path, "#{current_release}/public", :via => :scp, :recursive => true
  end
end

before 'deploy:restart', 'deploy:restart_bluepill'
after 'deploy:update_code', 'deploy:symlink_shared'

namespace :bundler do
  desc "Symlink bundled gems on each release"
  task :symlink_bundled_gems, :roles => :app do
    run "mkdir -p #{shared_path}/bundled_gems"
    run "ln -nfs #{shared_path}/bundled_gems #{release_path}/vendor/bundle"
  end

  desc "Install for production"
  task :install, :roles => :app do
    run "cd #{release_path} && bundle install --deployment"
  end
end

namespace :assets do
  desc "Bundle assets on production."
  task :bundle do
    run "cd #{current_release} && /usr/bin/env rake jammit:bundle_assets RAILS_ENV=production"
  end
end

after 'deploy:update_code', 'bundler:symlink_bundled_gems'
after 'deploy:update_code', 'bundler:install'
after 'bundler:install', 'assets:bundle'
