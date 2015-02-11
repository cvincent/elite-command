class Reply
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String
  field :user_id, :type => String
  field :topic_id, :type => String
  
  after_create :notify

  def user
    @user ||= User.find(self.user_id) rescue nil
  end
  
  def topic
    @topic ||= Topic.find(self.topic_id) rescue nil
  end

  protected

  def notify
    ActiveSupport::Notifications.instrument('ec.forum_post', reply: self)
  end
end
