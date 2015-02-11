SPREEDLY_PLANS_CONFIGS = {
  development: {
    api_key: 'REDACTED',
    site_name: 'elite-command-test',
    one_week_trial: 9215,
    one_week_trial_name: 'Premium (New User Free Trial)',
    one_week_price: 0,
    one_week_short_name: 'Free Trial',
    one_month: 9216,
    one_month_name: 'Premium (Monthly)',
    one_month_price: 6,
    one_month_short_name: 'Monthly',
    three_months: 9217,
    three_months_name: 'Premium (3-month)',
    three_months_price: 15,
    three_months_short_name: '3-month',
    one_year: 9218,
    one_year_name: 'Premium (Yearly)',
    one_year_price: 28,
    one_year_short_name: 'Yearly'
  },
  production: {
    api_key: 'REDACTED',
    site_name: 'elitecommand',
    one_week_trial: 9254,
    one_week_trial_name: 'Free 1-Week Trial',
    one_week_price: 0,
    one_week_short_name: 'Free Trial',
    one_month: 9255,
    one_month_name: 'Monthly',
    one_month_price: 6,
    one_month_short_name: 'Monthly',
    three_months: 9256,
    three_months_name: 'Quarterly',
    three_months_price: 15,
    three_months_short_name: '3-month',
    one_year: 9257,
    one_year_name: 'Yearly',
    one_year_price: 28,
    one_year_short_name: 'Yearly'
  }
}

SPREEDLY_PLANS_CONFIGS[:test] = SPREEDLY_PLANS_CONFIGS[:development]

SPREEDLY = SPREEDLY_PLANS_CONFIGS[Rails.env.to_sym]

RSpreedly::Config.setup do |config|
  config.api_key        = SPREEDLY[:api_key]
  config.site_name      = SPREEDLY[:site_name]
end

