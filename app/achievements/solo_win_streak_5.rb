class SoloWinStreak5 < Achievement
  @queue = :high

  triggered_on :end_turn

  class << self
    def display_name
      'Solo Rampage'
    end

    def description
      'Win five one-on-one matches in a row.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:command].to_json_hash)
    end

    def grant?(command)
      command = command.with_indifferent_access
      info = command[:ivars]
      streak = 5

      game = Game.find(info[:game_id])
      tom = User.where(username: 'TomServo').first

      if game.status == 'win' and game.starting_player_count == 2 and !game.defeated_users.include?(tom)
        user = game.winner_user

        streak_games = user.finished_games
        streak_games = streak_games.where(starting_player_count: 2)
        streak_games = straek_games.where(:defeated_players.nin => [tom._id])
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

