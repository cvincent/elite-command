class MoveUnit < GameCommand
  def initialize(game, user, params)
    super(game, user, params)

    @unit_location = @params.values_at(:unit_x, :unit_y, :unit_slot)
    @dest_x, @dest_y = *@params.values_at(:dest_x, :dest_y)
  end

  def execute
    require_current_player
    require_running_game
    unit = require_current_player_unit(*@unit_location)

    raise CommandError.new("Unit is capturing a base.") if @game.capturing_at?(*@unit_location[0..1])
    raise CommandError.new("No movement points.") if unit.movement_points == 0

    remaining_mv = require_destination_reachable(unit, @dest_x, @dest_y)

    move_unit(*@unit_location, @dest_x, @dest_y, nil)
    modify(unit, :movement_points, remaining_mv)
    modify(unit, :moved, true)

    if unit.attack_type == :exclusive
      modify(unit, :attacks, unit.attack_phases)
    end

    { :remaining_movement_points => remaining_mv }
  end

  protected

  def require_destination_reachable(unit, x, y)
    zoc_tiles = @game.rival_units.select do |u|
      u.can_zoc_unit_type?(unit.unit_type)
    end.map do |u|
      [u.x, u.y]
    end

    cost_map = {}

    @game.map.tiles_hash.each do |coords, tile_index|
      cost_map[coords] = unit.terrain_cost(@game.terrain_at(*coords), @game.unmodified_terrain_at(*coords))
    end

    pf = PathFinder.new(
      cost_map, unit, @game.rival_units
    )
    occupied_tiles = @game.units.map { |u| [u.x, u.y] } - [x, y]

    if unit.armor_type == :naval
      @game.terrain_modifiers.each do |tm|
        if tm.terrain_name == 'bridge'
          occupied_tiles += [tm.x, tm.y]
        end
      end
    end

    pf.possible_destination_tiles.except(*occupied_tiles)[[x, y]].tap do |remaining_mv|
      raise CommandError.new("Invalid destination.") unless remaining_mv
    end
  end
end
