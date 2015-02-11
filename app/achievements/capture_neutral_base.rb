class CaptureNeutralBase < Achievement
  @queue = :high

  triggered_on :base_captured
  has_tiers 1, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 100000

  class << self
    def display_name
      'This Land is My Land'
    end

    def description
      'Capture a neutral base.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:user_id], payload[:neutral])
    end

    def grant?(user_id, neutral)
      if neutral
        user = User.find(user_id)
        return grant_return(user.achieved!(self), user)
      else
        return grant_return(false)
      end
    end
  end
end

