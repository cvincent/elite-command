class PaypalTransaction
  include Mongoid::Document
  include Mongoid::Timestamps

  field :txn_id, :type => String

  validates_uniqueness_of :txn_id
end
