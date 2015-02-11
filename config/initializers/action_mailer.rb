case Rails.env
when 'development'
  ActionMailer::Base.default_url_options[:host] = 'elitecommand.dyndns.org:3000'
when 'production'
  ActionMailer::Base.default_url_options[:host] = 'elitecommand.net'
end
