require 'stringio'
require 'webrick'
require 'eventmachine'
require 'json'
require 'cgi'
require 'pp'



SAFARI_FILLER = "                                ,_-=(!7(7/zs_.\n                             .='  ' .`/,/!(=)Zm.\n               .._,,._..  ,-`- `,\\ ` -` -`\\\\7//WW.\n          ,v=~/.-,-\\- -!|V-s.)iT-|s|\\-.'   `///mK%.\n        v!`i!-.e]-g`bT/i(/[=.Z/m)K(YNYi..   /-]i44M.\n      v`/,`|v]-DvLcfZ/eV/iDLN\\D/ZK@%8W[Z..   `/d!Z8m\n     //,c\\(2(X/NYNY8]ZZ/bZd\\()/\\7WY%WKKW)   -'|(][%4.\n   ,\\\\i\\c(e)WX@WKKZKDKWMZ8(b5/ZK8]Z7%ffVM,   -.Y!bNMi\n   /-iit5N)KWG%%8%%%%W8%ZWM(8YZvD)XN(@.  [   \\]!/GXW[\n  / ))G8\\NMN%W%%%%%%%%%%8KK@WZKYK*ZG5KMi,-   vi[NZGM[\n i\\!(44Y8K%8%%%**~YZYZ@%%%%%4KWZ/PKN)ZDZ7   c=//WZK%!\n,\\v\\YtMZW8W%%f`,`.t/bNZZK%%W%%ZXb*K(K5DZ   -c\\\\/KM48\n-|c5PbM4DDW%f  v./c\\[tMY8W%PMW%D@KW)Gbf   -/(=ZZKM8[\n2(N8YXWK85@K   -'c|K4/KKK%@  V%@@WD8e~  .//ct)8ZK%8`\n=)b%]Nd)@KM[  !'\\cG!iWYK%%|   !M@KZf    -c\\))ZDKW%`\nYYKWZGNM4/Pb  '-VscP4]b@W%     'Mf`   -L\\///KM(%W!\n!KKW4ZK/W7)Z. '/cttbY)DKW%     -`  .',\\v)K(5KW%%f\n'W)KWKZZg)Z2/,!/L(-DYYb54%  ,,`, -\\-/v(((KK5WW%f\n \\M4NDDKZZ(e!/\\7vNTtZd)8\\Mi!\\-,-/i-v((tKNGN%W%%\n 'M8M88(Zd))///((|D\\tDY\\\\KK-`/-i(=)KtNNN@W%%%@%[\n  !8%@KW5KKN4///s(\\Pd!ROBY8/=2(/4ZdzKD%K%%%M8@%%\n   '%%%W%dGNtPK(c\\/2\\[Z(ttNYZ2NZW8W8K%%%%YKM%M%%.\n     *%%W%GW5@/%!e]_tZdY()v)ZXMZW%W%%%*5Y]K%ZK%8[\n      '*%%%%8%8WK\\)[/ZmZ/Zi]!/M%%%%@f\\ \\Y/NNMK%%!\n        'VM%%%%W%WN5Z/Gt5/b)((cV@f`  - |cZbMKW%%|\n           'V*M%%%WZ/ZG\\t5((+)L'-,,/  -)X(NWW%%\n                `~`MZ/DZGNZG5(((\\,    ,t\\\\Z)KW%@\n                   'M8K%8GN8\\5(5///]i!v\\K)85W%%f\n                     YWWKKKKWZ8G54X/GGMeK@WM8%@\n                      !M8%8%48WG@KWYbW%WWW%%%@\n                        VM%WKWK%8K%%8WWWW%%%@`\n                          ~*%%%%%%W%%%%%%%@~\n                             ~*MM%%%%%%@f`\n                                 '''''\n"



class Object
  def try(method, *args, &block)
    send(method, *args, &block)
  rescue NoMethodError
    nil
  end
end



module EliteCommandCometServer
  def post_init
    puts 'New connection (EliteCommandCometServer)'
    @connected = true
    @buffer = ''
    @content_length = nil
    @request = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
    @cmd = ''
    
    @subscription = nil
    send_new_messages
  end
  
  def receive_data(data)
    @buffer << data
    
    if !@content_length and @buffer.match(/^Content-Length: ([0-9]+)\r\n/)
      @content_length = $1.to_i
    end
    
    buffer_split = @buffer.split("\r\n\r\n")
    
    if (buffer_split[1] and buffer_split[1].length == @content_length) or (@buffer[-4..-1] == "\r\n\r\n" and (!@content_length or @content_length == 0))
      buffer = @buffer.gsub(/GET \/\?([^\s]+) HTTP/, 'GET / HTTP')
      @cmd = JSON.parse(CGI.unescape($1))
      pp @cmd
      @request.parse(StringIO.new(buffer))
      subscribe_to_channel(@request.query['channel'])
    end
  end
  
  def subscribe_to_channel(channel)
    @subscription = channel
    EliteCommandCometConduit.subscribe(channel, self)
    
    send_data "HTTP/1.1 200 OK\r\n" + \
      "Content-Type: text/html;charset=ISO-8859-1\r\n" + \
      "Cache-Control: private\r\n" + \
      "Pragma: no-cache\r\n" + \
      "\r\n"
    
    send_data(SAFARI_FILLER + "\r\n") if @request.header['user-agent'][0].index('AppleWebKit')
  end
  
  def send_new_messages
    if @subscription and message = EliteCommandCometConduit.receive_message(@subscription, self)
      received_message(message)
    end
    
    EventMachine.next_tick do
      send_new_messages
    end
  end
  
  def received_message(message, bypass_js = false)
    send_data(%{<script type="text/javascript">received_data(#{message['message'].inspect})</script>} + "\r\n\r\n")
  end
  
  def unbind
    puts 'Disconnection (EliteCommandCometServer)'
    @connected = false
  end
  
  def send_data(data)
    super(data) if @connected
  end
end



module EliteCommandMothershipServer
  def post_init
    puts 'New connection (EliteCommandMothershipServer)'
    @connected = true
    @buffer = ''
  end
  
  def receive_data(data)
    @buffer << data
    
    if @buffer.index("\r\n")
      messages = @buffer.split("\r\n")
      new_message = messages.shift
      @buffer = messages.join("\r\n")
      
      queue_message(new_message)
    end
  end
  
  def queue_message(new_message)
    m = JSON.parse(new_message)
    EliteCommandCometConduit.queue_message(m['channel'], m)
  end
  
  def unbind
    puts 'Disconnection (EliteCommandMothershipServer)'
    @connected = false
  end
  
  def send_data(data)
    super(data) if @connected
  end
end



class EliteCommandCometConduit
  @@messages = {}
  @@subscribers = {}
  
  def self.subscribe(channel, subscriber)
    @@subscribers[channel] ||= []
    @@subscribers[channel] << subscriber
  end
  
  def self.unsubscribe(channel, subscriber)
    @@subscribers[channel].try(:delete, subscriber)
    @@messages[channel].try(:delete, subscriber)
  end
  
  def self.queue_message(channel, message)
    @@messages[channel] ||= {}
    
    (@@subscribers[channel] || []).each do |subscriber|
      @@messages[channel][subscriber] ||= []
      @@messages[channel][subscriber] << message
    end
  end
  
  def self.receive_message(channel, subscriber)
    @@messages[channel].try(:[], subscriber).try(:shift)
  end
end



EventMachine.run do
  EventMachine.start_server 'localhost', 9000, EliteCommandCometServer
  EventMachine.start_server 'localhost', 9001, EliteCommandMothershipServer
  
  puts "Running Elite Command Comet and Mothership server"
end