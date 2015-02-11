FB_CONFIG = {
  development: {
    app_id: "REDACTED",
    secret: 'REDACTED'
  },
  production: {
    app_id: "REDACTED",
    secret: 'REDACTED'
  }
}

FB = FB_CONFIG[Rails.env.to_sym]
