root_path = File.absolute_path(File.join(__FILE__, '..', '..', '..'))
log_path = File.absolute_path(File.join(__FILE__, '..', '..', '..', 'log', 'bluepill.log'))
rake = "rake -f #{root_path}/Rakefile"

resque_workers = 5

Bluepill.application('elite_command', log_file: log_path) do |app|
  app.process('tom_servo') do |process|
    process_path = File.absolute_path(File.join(root_path, 'lib', 'daemons', 'simple_ai.rb'))
    pid_path = File.absolute_path(File.join(root_path, 'tmp', 'pids', 'tom_servo.pid'))
    stdout_path = File.absolute_path(File.join(root_path, 'log', 'tom_servo.log'))

    process.start_command = "/usr/bin/env RAILS_ENV=production ruby #{process_path}"
    process.pid_file = pid_path
    process.stdout = stdout_path
    process.daemonize = true

    process.checks :mem_usage, every: 10.seconds, below: 80.megabytes, times: 6
  end

  resque_workers.times do |i|
    app.process("resque_worker_#{i}") do |process|
      process.working_dir = root_path
      process.start_command = "/usr/bin/env QUEUES=high,low PIDFILE=#{root_path}/tmp/pids/resque_worker_#{i}.pid RAILS_ENV=production RACK_ENV=production APP_ROOT=#{root_path} #{rake} environment resque:work"
      process.pid_file = File.absolute_path(File.join(root_path, 'tmp', 'pids', "resque_worker_#{i}.pid"))
      process.stdout = File.absolute_path(File.join(root_path, 'log', "resque_worker_#{i}.log"))
      process.daemonize = true

      process.checks :mem_usage, every: 10.seconds, below: 80.megabytes, times: 6
    end
  end

  app.process('orbited') do |process|
    process.working_dir = root_path
    process.start_command = "/usr/local/bin/orbited -c #{root_path}/config/orbited.cfg"
    process.pid_file = File.absolute_path(File.join(root_path, 'tmp', 'pids', "orbited.pid"))
    process.stdout = File.absolute_path(File.join(root_path, 'log', "orbited.log"))
    process.daemonize = true

    process.checks :mem_usage, every: 10.seconds, below: 25.megabytes, times: 6
  end

  app.process('resque-web') do |process|
    process.working_dir = root_path
    process.start_command = "bundle exec resque-web -L --pid-file #{root_path}/tmp/pids/resque-web.pid"
    process.stop_command = "bundle exec resque-web -K --pid-file #{root_path}/tmp/pids/resque-web.pid"
    process.pid_file = "#{root_path}/tmp/pids/resque-web.pid"
    process.stdout = "#{root_path}/log/resque_web.log"
    process.daemonize = true
    
    process.checks :mem_usage, every: 10.seconds, below: 25.megabytes, times: 6
  end

  app.process("unicorn") do |process|
    process.working_dir = root_path
    process.pid_file = File.join(root_path, 'tmp', 'pids', 'unicorn.pid')

    process.start_command = "bundle exec unicorn_rails -c /var/www/ec/current/config/unicorn.rb -D -E production"
    process.stop_command = "kill -QUIT {{PID}}"
    process.restart_command = "kill -USR2 {{PID}}"

    process.uid = process.gid = 'root'

    process.start_grace_time = 60.seconds
    process.stop_grace_time = 60.seconds
    process.restart_grace_time = 60.seconds

    process.monitor_children do |child_process|
      child_process.stop_command = "kill -QUIT {{PID}}"

      child_process.checks :mem_usage, :every => 10.seconds, :below => 150.megabytes, :times => 6, :fires => :stop
      child_process.checks :cpu_usage, :every => 10.seconds, :below => 20, :times => 6, :fires => :stop
    end
  end
end

