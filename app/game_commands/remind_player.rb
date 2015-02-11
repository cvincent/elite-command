class RemindPlayer < GameCommand
  def initialize(game, user, params = {})
    super(game, user, params)
  end

  def execute
    require_player
    require_not_waiting_for_player
    require_current_player_exceeded_time_limit

    raise CommandError.new("Cannot send another reminder yet.") if !@game.can_send_reminder?

    UserMailer.turn_reminder(@game, @user).deliver rescue nil
    modify_game(:reminder_sent_at, Time.now)

    @game.send_chat_message(:info_message, "#{@user.username} sent a reminder to #{@game.current_user.username}.", @user)
  end

  def unexecute
    raise IrreversibleCommand
  end
end
