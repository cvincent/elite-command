class Topic
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :forum_id, :type => String
  field :user_id, :type => String
  field :subscribers, :type => Array, :default => []
  
  attr_accessor :body, :subscribe
  
  validates_presence_of :name, :allow_nil => false, :allow_blank => false
  
  before_create :set_poster_subscription
  after_create :create_initial_reply
  
  def user
    @user ||= User.find(self.user_id)
  end
  
  def forum
    @forum ||= Forum.find(self.forum_id)
  end
  
  def replies
    @replies ||= Reply.where(:topic_id => self._id.to_s).asc(:created_at)
  end

  def add_subscriber(user)
    self.subscribers << user._id
    self.modify('subscribers', nil, self.subscribers.uniq)
  end

  def remove_subscriber(user)
    self.modify('subscribers', nil, self.subscribers - [user._id])
  end

  def user_subscribed?(user)
    user and user.email_forum_updates and self.subscribers.include?(user._id)
  end
  
  protected

  def set_poster_subscription
    self.add_subscriber(self.user) if self.subscribe
  end
  
  def create_initial_reply
    r = Reply.create(:body => self.body, :user_id => self.user_id, :topic_id => self._id)
  end
end
