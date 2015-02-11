# A few view helpers to generate the necessary javascript to get
# connected to the Orbited server
module OrbitedHelper

  # Includes the necessary javascript files from the Orbited server (Orbited.js and stomp.js)
  # This should be called after prototype.js is included
  def orbited_javascript
    js = javascript_tag "document.domain = document.domain;"
    js += javascript_include_tag orbited_js
    js += javascript_tag initialize_js
    js += javascript_include_tag protocol_js
    js
  end

  # Connects to the the STOMP server and subscribes to each channel in channels
  # [:js]
  #   The JS framework that you are using, only :prototype and :jquery are supported. (string)
  # [:callbacks]
  #   Callbacks to pass to the stomp object (Hash). ie.
  #   {:onmessageframe => "function(frame) {alert(frame.body)}"}
  #   {:onconnectedframe => "function(frame) {alert(frame.body)}"}
  # [:user]
  #   Stomp username (string)
  # [:password]
  #   Stomp password (string)
  # [:delayed_connect]
  #   Assign it to true to delay the connection (Boolean)
  #
  def stomp_connect(channels, options = {})
    stomp_var = options[:var] || 'stomp'
    callbacks = options[:callbacks] || {}
    channels = [channels] unless channels.is_a? Array
    subscriptions = channels.map {|channel| "stomp.subscribe('/topic/#{channel}')"}.join(';')
    js = ""
    js << case options[:js].to_s
      when "jquery"
        "$(document).ready(function() {"
      else
        "Element.observe(window, 'load', function(){"
    end

    js << "document.domain = document.domain; "
    js << "var #{stomp_var} = new STOMPClient(); "
    js << "#{stomp_var}.onmessageframe = function(frame) {eval(frame.body)}; " unless callbacks[:onmessageframe]
    js << "#{stomp_var}.onconnectedframe = function(frame) {#{subscriptions}}; " unless callbacks[:onconnectedframe]
    callbacks.each do |callback, function|
      js << "#{stomp_var}.#{callback} = #{function}; "
    end
    user = options[:user] || OrbitedConfig.stomp_user || ''
    password = options[:password] || OrbitedConfig.stomp_password || ''
    host = OrbitedConfig.stomp_host
    port = OrbitedConfig.stomp_port
    stomp_connect = "#{stomp_var}.connect('#{host}', #{port}, '#{user}', '#{password}'); "
    if options[:delayed_connect]
      js << "#{stomp_var}.delayedConnect = function() {#{stomp_connect}};"
    else
      js << stomp_connect
    end

    js << case options[:js].to_s
      when "jquery"
        "$(window).bind('beforeunload', function() {#{stomp_var}.reset()});"
      else
        "Element.observe(window, 'beforeunload', function(){#{stomp_var}.reset()});"
    end
    js << "});"

    "try{\n#{js}\n} catch(err) {\n//Do nothing\n}"
  end

private
  def orbited_server_url
    request.ssl? ?
      "https://#{OrbitedConfig.ssl_host}:#{OrbitedConfig.ssl_port}" :
      "http://#{OrbitedConfig.host}:#{OrbitedConfig.port}"
  end

  def orbited_js
    "#{orbited_server_url}/static/Orbited.js?#{OrbitedConfig.version}"
  end

  def protocol_js
    "#{orbited_server_url}/static/protocols/#{OrbitedConfig.protocol}/#{OrbitedConfig.protocol}.js?#{OrbitedConfig.version}"
  end

  def initialize_js
  <<-EOS
    try {
      Orbited.settings.hostname = '#{request.ssl? ? OrbitedConfig.ssl_host : OrbitedConfig.host}';
      Orbited.settings.port = '#{request.ssl? ? OrbitedConfig.ssl_port : OrbitedConfig.port}';
      Orbited.settings.protocol = '#{request.ssl? ? "https" : "http"}'
      Orbited.settings.streaming = true;
      TCPSocket = Orbited.TCPSocket;
    } catch(err) {
      // Do nothing
    }
  EOS
  end

end
