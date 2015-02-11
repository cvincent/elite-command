class KillAUnit < Achievement
  @queue = :high

  triggered_on :attack
  has_tiers 1, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 100000

  class << self
    def display_name
      'Take That!'
    end

    def description
      'Kill an enemy unit.'
    end

    def enqueue_check!(payload)
      Resque.enqueue(self, payload[:command].to_json_hash)
    end

    def grant?(command)
      command = command.with_indifferent_access
      info = command[:ivars]

      if info[:defender_starting_health] - info[:attacker_damage] <= 0
        user = User.find(command[:user_id])
        return grant_return(user.achieved!(self), user)
      else
        return grant_return(false)
      end
    end
  end
end
