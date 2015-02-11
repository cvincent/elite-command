class Donation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :amount, type: Integer
end
