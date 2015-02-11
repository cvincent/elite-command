class BeginBuilding < GameCommand
  def initialize(game, user, params)
    super(game, user, params)
    @x, @y, @building = *@params.values_at(:x, :y, :building)
    @building = @building.to_sym
  end

  def execute
    require_current_player
    require_running_game
    unit = require_current_player_unit(@x, @y)

    raise CommandError.new("Unit can't build that.") unless unit.respond_to?(:can_build) and unit.can_build.include?(@building)
    raise CommandError.new("Not enough credits.") unless @game.user_credits(@user) >= unit.can_build[@building][:credits]

    validate_building

    modify(unit, :current_build, @building)
    modify(unit, :build_phase, -1 + unit.can_build[@building][:turns])
    modify(unit, :attacks, unit.attack_phases)
    modify(unit, :movement_points, 0)

    player_num = @game.player_number_for_user(@user)
    modify_credits(player_num, @game.user_credits(@user) - unit.can_build[@building][:credits])
  end

  protected

  def validate_building
    case @building
    when :plains
      raise CommandError.new("No woods to clear.") unless @game.terrain_at(@x, @y) == :woods
    when :road
      raise CommandError.new("Cannot build road there.") unless [:plains, :desert, :tundra].include?(@game.terrain_at(@x, @y))
    when :bridge
      raise CommandError.new("Cannot build bridge there.") unless [:shallow_water, :ford].include?(@game.terrain_at(@x, @y))

      prioritized_bridges = ['110110', '011011', '101101', '010010', '001001', '100100']
      connections = ''

      PathFinder.surrounding_tiles(@x, @y).each do |xy|
        t = @game.terrain_at(*xy)
        connections << ([:sea, :ford, :shallow_water, :void, :swamp, :bridge].include?(t) ? '0' : '1')
      end

      connections = connections.to_i(2)
      bridgeable = false

      prioritized_bridges.each do |bridge|
        bridge = bridge.to_i(2)
        if connections & bridge == bridge
          bridgeable = true
          break
        end
      end

      raise CommandError.new("Cannot build bridge there.") unless bridgeable
    when :destroy
      raise CommandError.new("Nothing to destroy.") unless [:road, :bridge].include?(@game.terrain_at(@x, @y))
    end
  end
end
