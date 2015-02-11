class UserAction
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :user_id, :type => String
  field :user_src, :type => String
  field :user_tid, :type => String

  before_save :record_user_activation

  def self.record(name, opts = {})
    cookie, user = opts.delete(:cookies), opts.delete(:user)
    uid, src, tid = nil, nil, nil

    if user
      uid = user._id.to_s
      src = user.src
      tid = user.tid
    else
      src = cookie[:src]
      tid = cookie[:tid]
    end

    create(:name => name, :user_id => uid, :user_src => src, :user_tid => tid)
  end

  protected

  def record_user_activation(override_time = false)
    if user = User.find(self.user_id) rescue nil
      at = override_time ? self.created_at : Time.now
      UserActivation.activate(user, self.name, at)
    end
  end
end
