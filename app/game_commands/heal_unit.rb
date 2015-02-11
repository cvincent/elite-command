class HealUnit < GameCommand
  def initialize(game, user, params)
    super(game, user, params)
    @x, @y = *@params.values_at(:x, :y)
  end

  def execute
    require_current_player
    require_running_game

    base = require_friendly_base(@x, @y)
    unit = require_current_player_unit(@x, @y)

    raise CommandError.new("Unit cannot be repaired there.") unless base.can_build_unit_type?(unit.unit_type)
    raise CommandError.new("Unit has not taken damage.") unless unit.health < 10
    raise CommandError.new("Cannot heal after attacking.") unless unit.attacked == false
    raise CommandError.new("Unit has already healed this turn.") unless !unit.healed

    modify(unit, :health, unit.health + ((10 - unit.health) / 2.0).ceil)
    modify(unit, :movement_points, 0)
    modify(unit, :attacks, unit.attack_phases)
    modify(unit, :healed, true)
  end
end
