Orbited on Rails
================

Orbited on Rails is a plugin that makes it easy for your Rails application to use Comet to push changes to your users.

[Comet][1], also known as Reverse Ajax and server push (among other nicknames),
is a method of pushing data to your users without polling. [Orbited](htttp://orbited.org) is one implementation of this
method that uses a Python push server that can interact with a number of messaging protocols such as STOMP, IRC, and XMPP.

Traditionally, when web devolopers have a need to broadcast any data to people currently using the site, such as people
using a chat interface, they would use polling. Each client browser would, after a certain interval, send a request
to the server to see if there had been any changes, and update accordingly. However, there are a few problems with this
method. If you set the interval too high, then some people might be waiting a while to see the changes. If the interval
is too low, then the server is constantly being hammered and could run out of resources.

Orbited to the rescue! Orbited allows browsers to hold a long connection to the server with little overhead so that
changes can be pushed to all connected clients simultaneously. This Rails plugin allows you to add Orbited support
in just a few lines of code.

Note:
Currently, this plugin only supports the STOMP protocol, but I hope to add support for the other protocols in the future.

## Requirements

* [Python 2.5][2] or greater
* [Twisted][3]
* [Orbited][4]
* The STOMP gem
* Prototype
* and of course, Ruby on Rails

## Installation

### Prerequisites

Installation instructions for the first few requirements can be found on the [Orbited installation page][5].

Install the STOMP gem with `gem install stomp`.

### Plugin

To install this plugin, type

	cd your/rails/app
	script/plugin install git://github.com/mallio/orbited

This will create an `orbited.yml` file in your config directory. 

## Configuration

Open `config/orbited.yml` in your text editor of choice. Reasonable defaults have been chosen.

Basic settings:

* `host` and `port`: These fields tell your application where the Orbited server is running 
* `protocol`: The messaging protocol you web application should use. Currently, the only supported value is `stomp`
* `stomp_host` and `stomp_port`: The location of your STOMP server
* `stomp_user` and `stomp_password`: If your stomp server requires a login, usethese fields
* `version`: Will be added to the end of included js files. Change this any time you upgrade your orbited version to force browsers to reload the files

Configuration settings used to generate the Orbited config file:

* `reactor`: Which Twisted reactor to use. Possible values are `select`, `epoll`, and `kqueue`. `select` is the only one that will work in Windows. [More info...][7]
* `morbidq`: Tells the Orbited server to use its built in MorbidQ STOMP server. This is not reccomended for production, but is convienient for development.
* `restrict_access`: Make the Orbited server only proxy requests to the STOMP server when the request comes from the host and port specified for the Orbited server.
* `ssl_enabled`: 1 to enable ssl. You will need the below fields to do so.
* `ssl_port`: Which port to use for the ssl server
* `ssl_key` and `ssl_crt`: The paths to the ssl key and certificate

Once you are happy with the settings in `orbited.yml`, type

	script/generate orbited_config

This will generate `config/orbited.cfg`. If you wish, you can further configure your Orbited server by editting this file, but if you run the generator again,
your changes will be overwritten. For possible options, see the [Orbited configuration page][6].

## Usage

Now that everything is set up, you can have Orbited running with your app in just a few steps. 

In the `<head>` of the view you want to use Orbited in, add the following lines:

	<%= orbited_javascript %>
	<%= stomp_connect('hello') %>

Make sure prototype.js is included as well. This will include the necessary js files, connect to your STOMP server, and subscribe to the channel 'hello'.
If you want to use some of the STOMP callbacks, you can do so by replacing the connect line with something like:

	<%= stomp_connect('hello', :onerror => 'errorHandler', :onclose => 'function(){alert("closed!")}') %>

Please note that by default the `onconnectedframe` callback is used to subscribe to the specified channel, and if you override it you will
need to subscribe to the channel on your own. Also, the `onmessageframe` callback defaults to evaluating the received data as javascript, and you
will need to override it to use your own handler.

Next, in your controller, you can write actions that send data to any user that is on your view.

	def add_line
	  data = render_to_string :update do |page|
	  	page['chat-window'].insert :bottom => params[:entry]
	  end
	  Orbited.send_data('hello', data)
	end

This will generate javascript to insert the 'entry' parameter into the 'chat-window' element, and then sends that data through the Orbited server to anyone
subscribed to the 'hello' channel.

## Special notes for Production

You will need to edit your orbited.yml file to reflect the actual host that the orbited server will run on. Also, you should also find a more production
ready STOMP server, as the built in MorbidQ was developed to be easy, not scalable. They list alternatives on [their website][8]. Also,
to generate the configuration file from your production settings in orbited.yml, type

	script/generate orbited_config production

[1]: http://en.wikipedia.org/wiki/Comet_(programming)
[2]: http://www.python.org/
[3]: http://twistedmatrix.com/trac/
[4]: http://orbited.org
[5]: http://orbited.org/wiki/Installation
[6]: http://orbited.org/wiki/Configuration
[7]: http://orbited.org/wiki/Configuration#reactor
[8]: http://morbidq.com/
