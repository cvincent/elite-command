class BeatTomServo < Achievement
  @queue = :high

  triggered_on :end_turn

  class << self
    def display_name
      'Robocide!'
    end

    def description
      'Win a match against TomServo.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:command].to_json_hash)
    end

    def grant?(command)
      command = command.with_indifferent_access
      info = command[:ivars]

      game = Game.find(info[:game_id])
      tom = User.where(username: 'TomServo').first

      if game.status == 'win' and game.defeated_users.include?(tom)
        user = game.winner_user
        return grant_return(user.achieved!(self), user)
      else
        return grant_return(false)
      end
    end
  end
end
