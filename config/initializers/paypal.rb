PAYPAL_SUBS = {
  monthly: {
    price: 6.00,
    period: 1,
    period_unit: 'M',
    length: 1.month,
    identifier: 'Monthly',
    name: 'Elite Command Monthly Subscription'
  },
  quarterly: {
    price: 15.00,
    period: 3,
    period_unit: 'M',
    length: 3.months,
    identifier: '3-Month',
    name: 'Elite Command 3-Month Subscription'
  },
  yearly: {
    price: 40.00,
    period: 12,
    period_unit: 'M',
    length: 12.months,
    identifier: 'Yearly',
    name: 'Elite Command Yearly Subscription'
  }
}

PAYPAL_AUTH_ENVS = {
  development: {
    :merchant_id => "REDACTED",
    :cert_id => "REDACTED",
    :paypal_public_cert => File.read("#{Rails.root}/config/paypal_certs/paypal_public_sandbox.pem"),
    :elite_public_cert => File.read("#{Rails.root}/config/paypal_certs/elite_public_sandbox.pem"),
    :elite_private_cert => File.read("#{Rails.root}/config/paypal_certs/elite_private.pem"),
    :base_uri => 'https://www.sandbox.paypal.com'
  },
  production: {
    :merchant_id => "REDACTED",
    :cert_id => "REDACTED",
    :paypal_public_cert => File.read("#{Rails.root}/config/paypal_certs/paypal_public.pem"),
    :elite_public_cert => File.read("#{Rails.root}/config/paypal_certs/elite_public.pem"),
    :elite_private_cert => File.read("#{Rails.root}/config/paypal_certs/elite_private.pem"),
    :base_uri => 'https://www.paypal.com'
  }
}

PAYPAL_AUTH = PAYPAL_AUTH_ENVS[Rails.env.to_sym]
