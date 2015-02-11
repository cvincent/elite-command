require 'aws/s3'

AWS_DEFAULT_S3_BUCKET = 'REDACTED'
AWS_ACCESS_KEY_ID = 'REDACTED'
AWS_SECRET_ACCESS_KEY = 'REDACTED'
AWS_ENDPOINT = 'REDACTED'

ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  :access_key_id     => AWS_ACCESS_KEY_ID,
  :secret_access_key => AWS_SECRET_ACCESS_KEY
