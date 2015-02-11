class Attack < GameCommand
  def initialize(game, user, params)
    super(game, user, params)

    @unit_location = @params.values_at(:unit_x, :unit_y)
    @target_location = @params.values_at(:target_x, :target_y)
  end

  def execute
    require_current_player
    require_running_game
    attacker = require_current_player_unit(*@unit_location)
    defender = require_rival_player_unit(*@target_location)

    raise CommandError.new("Unit has no attack phases left.") unless attacker.has_enough_attack_points_to_attack?
    raise CommandError.new("Unit not allowed to attack.") unless attacker.attack_allowed_by_attack_type?
    raise CommandError.new("Unit unable to attack target.") unless attacker.can_attack_unit_type?(defender.unit_type)
    raise CommandError.new("Unit is capturing a base.") if @game.capturing_at?(*@unit_location)

    require_defender_within_range(attacker, defender)

    attacker_terrain = @game.terrain_at(attacker.x, attacker.y)
    defender_terrain = @game.terrain_at(defender.x, defender.y)

    @attacker_damage = attacker.calculate_damage(attacker_terrain, defender, defender_terrain, @game.capturing_at?(*@target_location))

    @defender_damage = 0
    if target_within_range?(defender, attacker) and defender.can_attack_unit_type?(attacker.unit_type)
      @defender_damage = defender.calculate_damage(defender_terrain, attacker, attacker_terrain)
    end

    modify(defender, :health, defender.health - @attacker_damage)
    modify(attacker, :health, attacker.health - @defender_damage)

    modify(defender, :flank_penalty, defender.flank_penalty + 1)

    if attacker.health <= 0
      destroy_unit(attacker)
    else
      if [:move_attack, :exclusive].include?(attacker.attack_type)
        modify(attacker, :movement_points, 0)
      end

      modify(attacker, :attacks, attacker.attacks + 1)
      modify(attacker, :attacked, true)
    end

    if defender.health <= 0
      destroy_unit(defender)
      if @game.capturing_at?(*@target_location)
        cancel_capture(@game.base_at(*@target_location))
      end
    end

    ActiveSupport::Notifications.instrument('ec.attack', command: self)

    return { :attacker_damage => @attacker_damage, :defender_damage => @defender_damage }
  end

  def unexecute
    raise IrreversibleCommand
  end

  protected

  def require_rival_player_unit(x, y)
    @game.unit_at(x, y).tap do |unit|
      raise CommandError.new("No such target.") unless unit
      raise CommandError.new("Targeted unit is friendly.") if unit.player_id == @user._id.to_s
    end
  end

  def require_defender_within_range(attacker, defender)
    in_range = target_within_range?(attacker, defender)
    raise CommandError.new("Targeted unit is not within range.") unless in_range
  end

  def target_within_range?(attacker, defender)
    range_cost_map = {}
    
    @game.map.tiles_hash.each do |coords, tile_index|
      range_cost_map[coords] = 1
    end

    rf = RangeFinder.new(range_cost_map, attacker)
    rf.possible_destination_tiles.keys.include?([defender.x, defender.y])
  end
end
