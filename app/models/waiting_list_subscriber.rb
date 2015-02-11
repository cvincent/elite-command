class WaitingListSubscriber
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email, :type => String
  
  validates_format_of :email, :with => /^.+@.+$/, :message => 'must be valid.', :allow_blank => false, :allow_nil => false
  validates_uniqueness_of :email
end
