if Rails.env == 'development'
  class EndATurnTiered < Achievement
    @queue = :high

    triggered_on :end_turn
    has_tiers 5, 10, 15, 20

    class << self
      def display_name
        'Ended a turn!'
      end

      def description
        'End your turn repeatedly!'
      end

      def enqueue_check!(payload)
        Resque.enqueue(self, payload[:command].to_json_hash[:user_id].to_s)
      end

      def grant?(user_id)
        # No checks... the user ended their fucking turn
        user = User.find(user_id)
        return grant_return(user.achieved!(self), user)
      end
    end
  end
end
