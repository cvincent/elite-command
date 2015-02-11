module ApplicationHelper
  def button_to_url(name, url, opts = nil)
    button_to_function(name, "document.location.href = '#{url}'", opts)
  end

  def user_link(user)
    link_to user.username, user_url(user),
      class: (user.donated_ever? ? 'donator' : '')
  end

  def support_message
    "Support Elite Command! Disable these ads for a month with a small ".html_safe +
      link_to('donation', donate_url) +
      '.'.html_safe
  end

  def exclude_ads?
    [
      ['home', 'index'],
      ['home', 'donate'],
      ['home', 'thank_you'],
      ['users', 'new'],
      ['users', 'create']
    ].include?([params[:controller], params[:action]])
  end

  def paypal_sub_button(sub, user, type = :create)
    sub = PAYPAL_SUBS[sub]
    vals = {
      :charset => 'utf-8',
      :business => PAYPAL_AUTH[:merchant_id],
      :cert_id => PAYPAL_AUTH[:cert_id],
      :cmd => '_xclick-subscriptions',
      :item_name => sub[:name],
      :item_number => sub[:identifier],
      :currency_code => 'USD',
      :a3 => sub[:price],
      :p3 => sub[:period],
      :t3 => sub[:period_unit],
      :src => 1,
      :custom => user.id.to_s,
      :email => user.email,
      :return => user_url(user, :post_sub => 'true'),
      :cancel_return => url_for(:controller => :home, :action => :why_subscribe),
      :notify_url => paypal_ipn_users_url,
      :no_shipping => 1,
      :no_note => 1
    }
    vals[:modify] = 2 if type == :modify

    locals = {
      :type => type,
      :paypal_data => encrypt_paypal_vals(vals),
      :cmd => (type != :unsubscribe ? '_s-xclick' : '_subscr-find')
    }

    render :partial => 'layouts/paypal_sub_btn', :locals => locals
  end

  def paypal_donate_button(user)
    vals = {
      :charset => 'utf-8',
      :business => PAYPAL_AUTH[:merchant_id],
      :cert_id => PAYPAL_AUTH[:cert_id],
      :cmd => '_donations',
      :currency_code => 'USD',
      :custom => user.id.to_s,
      :email => user.email,
      :return => thank_you_url,
      :cancel_return => donate_url,
      :notify_url => paypal_donation_ipn_users_url,
      :no_shipping => 1,
      :no_note => 1,
      item_name: 'Elite Command Donation',
      cbt: 'Return to Elite Command'
    }

    locals = {
      unencrypted: vals,
      :paypal_data => encrypt_paypal_vals(vals),
      :cmd => '_s-xclick'
    }

    render :partial => 'layouts/paypal_donate_btn', :locals => locals
  end

  protected

  def encrypt_paypal_vals(vals)
    signed = OpenSSL::PKCS7::sign(
      OpenSSL::X509::Certificate.new(PAYPAL_AUTH[:elite_public_cert]),
      OpenSSL::PKey::RSA.new(PAYPAL_AUTH[:elite_private_cert], ''),
      vals.map { |key, value| "#{key}=#{value}" }.join("\n"), [], OpenSSL::PKCS7::BINARY
    )

    OpenSSL::PKCS7::encrypt(
      [OpenSSL::X509::Certificate.new(PAYPAL_AUTH[:paypal_public_cert])],
      signed.to_der,
      OpenSSL::Cipher::Cipher::new("DES3"),
      OpenSSL::PKCS7::BINARY
    ).to_s.gsub("\n", '')
  end
end
