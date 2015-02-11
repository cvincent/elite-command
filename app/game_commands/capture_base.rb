class CaptureBase < GameCommand
  def initialize(game, user, params)
    super(game, user, params)
    @x, @y = *@params.values_at(:x, :y)
  end

  def execute
    require_current_player
    require_running_game
    base = require_rival_base(@x, @y)
    unit = require_current_player_unit(@x, @y)
    raise CommandError.new("Unit cannot capture.") unless unit.can_capture?

    start_capture(base, @user)

    {}
  end
end
