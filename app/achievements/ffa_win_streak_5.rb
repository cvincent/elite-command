class FfaWinStreak5 < Achievement
  @queue = :high

  triggered_on :end_turn

  class << self
    def display_name
      'FFA Rampage'
    end

    def description
      'Win five free-for-all matches in a row.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:command].to_json_hash)
    end

    def grant?(command)
      command = command.with_indifferent_access
      info = command[:ivars]
      streak = 5

      game = Game.find(info[:game_id])

      if game.status == 'win' and game.starting_player_count > 2
        user = game.winner_user
        streak_games = user.finished_games.where(:starting_player_count.gt => 2)
        streak_games = streak_games.desc(:turn_started_at).limit(streak).to_a
        if streak_games.size == streak and streak_games.all? { |g| g.winner.to_s == user.id.to_s }
          return grant_return(user.achieved!(self), user)
        end
      else
        return grant_return(false)
      end
    end
  end
end

