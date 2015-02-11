class PublishMap < Achievement
  @queue = :high

  triggered_on :map_published
  has_tiers 1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 100000

  class << self
    def display_name
      'Cartographer'
    end

    def description
      'Publish a map.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:map].user_id.to_s)
    end

    def grant?(user_id)
      user = User.find(user_id)
      return grant_return(user.achieved!(self), user)
    end
  end
end

