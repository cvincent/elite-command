class FieldHealUnit < GameCommand
  def initialize(game, user, params)
    super(game, user, params)
    @x, @y = *@params.values_at(:x, :y)
    @tx, @ty = *@params.values_at(:tx, :ty)
  end

  def execute
    require_current_player
    require_running_game

    unit = require_current_player_unit(@x, @y)
    target = require_current_player_unit(@tx, @ty)

    raise CommandError.new("Cannot heal that unit type.") unless unit.can_heal_unit_type?(target.unit_type)
    raise CommandError.new("Unit has not taken damage.") unless target.health < 10
    raise CommandError.new("Cannot heal after attacking.") unless unit.attacks == 0

    if !PathFinder.surrounding_tiles(@x, @y).include?([@tx, @ty])
      raise CommandError.new("Unit not within range.")
    end

    modify(target, :health, target.health + ((10 - target.health) / 3.0).ceil)
    modify(unit, :movement_points, 0)
    modify(unit, :attacks, unit.attack_phases)
  end
end
