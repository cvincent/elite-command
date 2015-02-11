class LoadUnit < GameCommand
  def initialize(game, user, params)
    super(game, user, params)

    @x, @y = *@params.values_at(:x, :y)
    @tx, @ty = *@params.values_at(:tx, :ty)
  end

  def execute
    require_current_player
    require_running_game
    unit = require_current_player_unit(@x, @y)
    transport = require_current_player_unit(@tx, @ty)

    raise CommandError.new("Unit is capturing a base.") if @game.capturing_at?(@x, @y)

    if !PathFinder.surrounding_tiles(@x, @y).include?([@tx, @ty])
      raise CommandError.new("Unit not within range of the transport.")
    end

    raise CommandError.new("Unit has summoning sickness.") if unit.summoning_sickness
    raise CommandError.new("Cannot load that unit type.") if !transport.transport_armor_types.include?(unit.armor_type)
    raise CommandError.new("Not enough space.") if transport.loaded_capacity + transport.transport_armor_types[unit.armor_type] > transport.transport_capacity

    move_unit(unit.x, unit.y, nil, @tx, @ty, transport.loaded_units.size)
  end
end
