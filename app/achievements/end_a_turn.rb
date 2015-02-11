if Rails.env == 'development'
  class EndATurn < Achievement
    @queue = :high

    triggered_on :end_turn

    class << self
      def display_name
        'Ended a turn!'
      end

      def description
        'End your turn!'
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
