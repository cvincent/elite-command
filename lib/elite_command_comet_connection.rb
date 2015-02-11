require 'rev'
require 'json'

HOST = 'localhost'
PORT = 4321

class EliteCommandCometConnection < Rev::TCPSocket
  def on_connect
    puts "#{remote_addr}:#{remote_port} connected (EliteCommandCometConnection)"
  end
  
  def on_close
    puts "#{remote_addr}:#{remote_port} disconnected (EliteCommandCometConnection)"
  end
  
  def on_read(data)
    write data
  end
end

class EliteCommandMothershipCometConduit < Rev::TCPSocket
  event_callback :on_mothership_message_parse
  
  def on_mothership_message_parse
    puts 'checking...'
    if EliteCommandMothershipConnection.messages
      on_mothership_message(EliteCommandMothershipConnection.messages.inspect)
    end
  end
  
  def on_mothership_message(message)
    puts 'mothership message'
  end
end

class EliteCommandCometTestConnection < EliteCommandMothershipCometConduit
  def on_connect
    puts "#{remote_addr}:#{remote_port} connected (EliteCommandCometTestConnection)"
    
    @buffer = ''
    @sub = ''
  end
  
  def on_close
    puts "#{remote_addr}:#{remote_port} disconnected (EliteCommandCometTestConnection)"
  end
  
  def on_read(data)
    @buffer << data
    
    if @buffer.index("\r\n")
      messages = @buffer.split("\r\n")
      new_message = messages.shift
      @buffer = messages.join("\r\n")
      
      @sub = new_message
      write "Set @sub to #{new_message}...\n"
    end
  end
end


class EliteCommandMothershipConnection < Rev::TCPSocket
  def on_connect
    puts "#{remote_addr}:#{remote_port} connected (EliteCommandMothershipConnection)"
    
    @buffer = ''
  end
  
  def on_close
    puts "#{remote_addr}:#{remote_port} disconnected (EliteCommandMothershipConnection)"
  end
  
  def on_read(data)
    @buffer << data
    
    if @buffer.index("\n")
      messages = @buffer.split("\n")
      new_message = messages.shift
      @buffer = messages.join("\n")
      
      process_message(JSON.parse(new_message))
    end
  end
  
  def process_message(message)
    
  end
end

comet_server = Rev::TCPServer.new(HOST, PORT, EliteCommandCometConnection)
comet_server.attach(Rev::Loop.default)

mothership_server = Rev::TCPServer.new(HOST, 9000, EliteCommandMothershipConnection)
mothership_server.attach(Rev::Loop.default)

test_comet_server = Rev::TCPServer.new(HOST, 9001, EliteCommandCometTestConnection)
test_comet_server.attach(Rev::Loop.default)

puts "Elite Command Comet and Mothership servers listening on #{HOST}:#{PORT}"
Rev::Loop.default.run