class ForceSurrender < EndTurn
  def initialize(game, user, params = {})
    super(game, game.current_user, surrender: true, forced_by: user._id.to_s)
  end

  def execute
    surrendering_user = @user
    @user = User.find(@params[:forced_by])

    require_player
    require_not_waiting_for_player
    require_current_player_exceeded_time_limit
    require_current_player_exceeded_skip_limit

    @user = surrendering_user

    super
  end

  def unexecute
    raise IrreversibleCommand
  end
end
