class GlobalChatMessage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :message, type: String

  def user
    @user ||= User.find(self.user_id)
  end

  def user=(user)
    @user = user
    self.user_id = user._id.to_s
  end

  def to_json_hash
    {
      id: self._id.to_s,
      created_at: self.created_at,
      username: self.user.username,
      user_id: self.user_id.to_s,
      message: self.message
    }
  end
end
