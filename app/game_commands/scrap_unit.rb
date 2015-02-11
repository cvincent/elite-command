class ScrapUnit < GameCommand
  def initialize(game, user, params)
    super(game, user, params)
    @x, @y = *@params.values_at(:x, :y)
  end

  def execute
    require_current_player
    require_running_game

    base = require_friendly_base(@x, @y)
    unit = require_current_player_unit(@x, @y)

    raise CommandError.new("Unit cannot be scrapped there.") unless base.can_build_unit_type?(unit.unit_type)
    raise CommandError.new("Cannot scrap after attacking.") unless unit.attacks == 0

    destroy_unit(unit)
    modify_credits(@game.player_number_for_user(@user), @game.user_credits(@user) + unit.scrap_value)
  end
end
