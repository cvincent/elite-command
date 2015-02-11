class SkipPlayer < EndTurn
  def initialize(game, user, params = {})
    params[:skipped_by] = user._id.to_s
    params[:skipping] = true
    super(game, game.current_user, params)
  end

  def execute
    skipping = @user
    @user = User.find(@params[:skipped_by])

    require_player
    require_not_waiting_for_player
    require_current_player_exceeded_time_limit

    @game.send_chat_message(:info_message, "#{@user.username} skipped #{skipping.username}.", @user)
    modify_skip_count(skipping, @game.player_skip_count(skipping) + 1)

    @user = skipping
    super
  end

  def unexecute
    raise IrreversibleCommand
  end
end
