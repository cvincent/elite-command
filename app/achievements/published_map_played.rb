class PublishedMapPlayed < Achievement
  @queue = :high

  triggered_on :game_started
  has_tiers 1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 100000

  class << self
    def display_name
      'Master Cartographer'
    end

    def description
      'One of your published maps was played.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, {
        player_id: payload[:game].players[0].to_s,
        user_id: payload[:game].map.user_id.to_s,
        map_id: payload[:game].map_id.to_s
      })
    end

    def grant?(payload)
      player = User.find(payload['player_id'])
      user = User.find(payload['user_id'])
      map = Map.find(payload['map_id'])

      if player.id.to_s != map.user_id.to_s
        return grant_return(user.achieved!(self), user)
      end

      return grant_return(false)
    end
  end
end
