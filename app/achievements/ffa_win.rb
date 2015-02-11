class FfaWin < Achievement
  @queue = :high

  triggered_on :end_turn
  has_tiers 1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 100000

  class << self
    def display_name
      'Killer in the Fray'
    end

    def description
      'Win a free-for-all match.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:command].to_json_hash)
    end

    def grant?(command)
      command = command.with_indifferent_access
      info = command[:ivars]

      game = Game.find(info[:game_id])

      if game.status == 'win' and game.starting_player_count > 2
        user = game.winner_user
        return grant_return(user.achieved!(self), user)
      else
        return grant_return(false)
      end
    end
  end
end

