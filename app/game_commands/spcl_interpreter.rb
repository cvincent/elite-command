class SpclInterpreter
  def initialize(game)
    @game = game
  end

  def execute(change)
    change = change.dup
    inst = change.shift
    self.send(:"execute_#{inst}", *change)
  end

  def unexecute(change)
    change = change.dup
    inst = change.shift
    self.send(:"unexecute_#{inst}", *change)
  end

  def execute_modify(object_type, x, y, attribute, value, old_value)
    obj = (object_type == :unit ? @game.unit_at(x, y) : @game.base_at(x, y))
    obj.send(:"#{attribute}=", value)
  end

  def unexecute_modify(object_type, x, y, attribute, value, old_value)
    obj = (object_type == :unit ? @game.unit_at(x, y) : @game.base_at(x, y))
    obj.send(:"#{attribute}=", old_value)
  end

  def execute_modify_loaded_unit(tx, ty, slot, attr, val, old_val)
    obj = @game.unit_at(tx, ty, slot)
    obj.send(:"#{attr}=", val)
  end

  def unexecute_modify_loaded_unit(tx, ty, slot, attr, val, old_val)
    obj = @game.unit_at(tx, ty, slot)
    obj.send(:"#{attr}=", old_val)
  end

  def execute_modify_game(attr, val, old_val)
    @game.send(:"#{attr}=", val)
  end

  def unexecute_modify_game(attr, val, old_val)
    @game.send(:"#{attr}=", old_val)
  end

  def execute_modify_credits(player_num, val, old_val)
    @game.set_player_credits(player_num, val)
  end

  def unexecute_modify_credits(player_num, val, old_val)
    @game.set_player_credits(player_num, old_val)
  end

  def execute_create_unit(player_num, player_id, unit_type, x, y)
    @game.units << Unit.new(unit_type, player_num, x, y)
    @game.units.last.player_id = player_id
  end

  def unexecute_create_unit(player_num, player_id, unit_type, x, y)
    @game.units.delete(@game.unit_at(x, y))
  end

  def execute_destroy_unit(x, y, old_unit_json)
    @game.units.delete(@game.unit_at(x, y))
  end

  def unexecute_destroy_unit(x, y, old_unit_json)
    @game.units << Unit.from_json_hash(old_unit_json)
  end

  def execute_create_terrain_modifier(tm, x, y)
    @game.terrain_modifiers << TerrainModifier.new(tm, x, y)
  end

  def unexecute_create_terrain_modifier(tm, x, y)
    @game.terrain_modifiers.delete(@game.terrain_modifier_at(x, y))
  end

  def execute_destroy_terrain_modifier(x, y, old_tm_json)
    @game.terrain_modifiers.delete(@game.terrain_modifier_at(x, y))
  end

  def unexecute_destroy_terrain_modifier(x, y, old_tm_json)
    @game.terrain_modifiers << TerrainModifier.from_json_hash(old_tm_json)
  end

  def execute_move_unit(fx, fy, fslot, tx, ty, tslot)
    unit = @game.unit_at(fx, fy, fslot)

    if fslot
      transport = @game.unit_at(fx, fy)
      transport.loaded_units.delete(unit)
      @game.units << unit
    end

    if tslot
      @game.units.delete(unit)
      transport = @game.unit_at(tx, ty)

      if tslot >= transport.loaded_units.size
        transport.loaded_units << unit
      else
        transport.loaded_units.insert(tslot, unit)
      end
    end

    unit.x = tx
    unit.y = ty

    unit.loaded_units.each do |lu|
      lu.x = unit.x
      lu.y = unit.y
    end
  end

  def unexecute_move_unit(fx, fy, fslot, tx, ty, tslot)
    execute_move_unit(tx, ty, tslot, fx, fy, fslot)
  end

  def execute_modify_skip_count(player_num, val, old_val)
    @game.player_skips[player_num - 1] = val
  end

  def unexecute_modify_skip_count(player_num, val, old_val)
    @game.player_skips[player_num - 1] = old_val
  end

  def execute_defeat_player(player_num)
    user = @game.user_for_player_number(player_num)
    @game.defeated_players << user._id
  end

  def unexecute_defeat_player(player_num)
    user = @game.user_for_player_number(player_num)
    @game.defeated_players.delete(user._id)
  end
end
