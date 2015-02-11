class PostToForum < Achievement
  @queue = :high

  triggered_on :forum_post
  has_tiers 1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 100000

  class << self
    def display_name
      'Communications Officer'
    end

    def description
      'Post a topic or reply to the forum.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:reply].user_id.to_s)
    end

    def grant?(user_id)
      user = User.find(user_id)
      return grant_return(user.achieved!(self), user)
    end
  end
end
