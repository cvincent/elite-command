rake = 'bundle exec rake'
root_path = File.absolute_path(File.join(__FILE__, '..', '..', '..'))
log_path = File.absolute_path(File.join(root_path, 'log', 'bluepill.log'))

resque_workers = 1

Bluepill.application('elite_command', log_file: log_path) do |app|
  app.process('tom_servo') do |process|
    process_path = File.absolute_path(File.join(root_path, 'lib', 'daemons', 'simple_ai.rb'))
    pid_path = File.absolute_path(File.join(root_path, 'tmp', 'pids', 'tom_servo.pid'))
    stdout_path = File.absolute_path(File.join(root_path, 'log', 'tom_servo.log'))

    process.start_command = "ruby #{process_path}"
    process.pid_file = pid_path
    process.stdout = stdout_path
    process.daemonize = true

    process.checks :mem_usage, every: 10.seconds, below: 80.megabytes, times: 6
  end

  resque_workers.times do |i|
    app.process("resque_worker_#{i}") do |process|
      process.working_dir = root_path
      process.start_command = "cd #{root_path} && QUEUES=high,low PIDFILE=#{root_path}/tmp/pids/resque_worker_#{i}.pid nohup #{rake} environment resque:work"
      process.pid_file = File.absolute_path(File.join(root_path, 'tmp', 'pids', "resque_worker_#{i}.pid"))
      process.stdout = File.absolute_path(File.join(root_path, 'log', "resque_worker_#{i}.log"))

      process.checks :mem_usage, every: 10.seconds, below: 80.megabytes, times: 6
    end
  end

  app.process('orbited') do |process|
    process.working_dir = root_path
    process.start_command = "/usr/local/bin/orbited -c #{root_path}/config/orbited_dev.cfg"
    process.pid_file = File.absolute_path(File.join(root_path, 'tmp', 'pids', "orbited.pid"))
    process.stdout = File.absolute_path(File.join(root_path, 'log', "orbited.log"))
    process.daemonize = true

    process.checks :mem_usage, every: 10.seconds, below: 25.megabytes, times: 6
  end
end
