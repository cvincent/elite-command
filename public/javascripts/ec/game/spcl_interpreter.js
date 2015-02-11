var SpclInterpreter = new JS.Class(Dialog, {
  initialize: function(game) {
    this.game = game;
  },

  execute: function(change) {
    var c = change.slice(0);
    var inst = c.shift();
    this['execute_' + inst].apply(this, c);
  },

  unexecute: function(change) {
    var c = change.slice(0);
    var inst = c.shift();
    this['unexecute_' + inst].apply(this, c);
  },

  execute_modify: function(object_type, x, y, attribute, value, old_value) {
    var obj = (object_type == 'unit' ? this.game.unit_at(x, y) : this.game.base_at(x, y));
    this._set_attribute(obj, attribute, value);
  },

  unexecute_modify: function(object_type, x, y, attribute, value, old_value) {
    var obj = (object_type == 'unit' ? this.game.unit_at(x, y) : this.game.base_at(x, y));
    this._set_attribute(obj, attribute, old_value);
  },

  execute_modify_loaded_unit: function(tx, ty, slot, attr, val, old_val) {
    var obj = this.game.unit_at(tx, ty, slot);
    this._set_attribute(obj, attr, val);
  },

  unexecute_modify_loaded_unit: function(tx, ty, slot, attr, val, old_val) {
    var obj = this.game.unit_at(tx, ty, slot);
    this._set_attribute(obj, attr, old_val);
  },

  execute_modify_game: function(attr, val, old_val) {
    this._set_attribute(this.game, attr, val);
  },

  unexecute_modify_game: function(attr, val, old_val) {
    this._set_attribute(this.game, attr, old_val);
  },

  execute_modify_credits: function(player_num, val, old_val) {
    this.game.set_player_num_credits(player_num, val);
  },

  unexecute_modify_credits: function(player_num, val, old_val) {
    this.game.set_player_num_credits(player_num, old_val);
  },

  execute_create_unit: function(player_num, player_id, unit_type, x, y) {
    var u = new Unit({
      unit_type: unit_type, player: player_num, player_id: player_id,
      flank_penalty: 0, loaded_units: [], x: x, y: y, health: 10,
      attacks: GameConfig.units[unit_type].attack_phases, movement_points: 0
    });
    this.game.units.add(u);
    u.add_to_map(this.game.map);
  },

  unexecute_create_unit: function(player_num, player_id, unit_type, x, y) {
    var u = this.game.unit_at(x, y);
    this.game.units.remove(u);
    u.remove();
  },

  execute_destroy_unit: function(x, y, old_unit_json) {
    var u = this.game.unit_at(x, y);
    this.game.units.remove(u);
    u.remove();
  },

  unexecute_destroy_unit: function(x, y, old_unit_json) {
    var u = new Unit(old_unit_json);
    this.game.units.add(u);
    u.add_to_map(this.game.map);
  },

  execute_create_terrain_modifier: function(tm, x, y) {
    var tm = new TerrainModifier({
      terrain_name: tm, x: x, y: y
    });
    this.game.add_terrain_modifier(tm);
  },

  unexecute_create_terrain_modifier: function(tm, x, y) {
    this.game.remove_terrain_modifier(this.game.terrain_modifier_at(x, y));
  },

  execute_destroy_terrain_modifier: function(x, y, old_tm_json) {
    this.game.remove_terrain_modifier(this.game.terrain_modifier_at(x, y));
  },

  unexecute_destroy_terrain_modifier: function(x, y, old_tm_json) {
    var tm = new TerrainModifier(old_tm_json);
    this.game.add_terrain_modifier(tm);
  },

  execute_move_unit: function(fx, fy, fslot, tx, ty, tslot) {
    var unit = this.game.unit_at(fx, fy, fslot);

    if (fslot != null && fslot != undefined) {
      var transport = this.game.unit_at(fx, fy);
      transport.loaded_units.splice(fslot, 1);
      this.game.units.add(unit);
      unit.add_to_map(this.game.map);
      transport.set_transport_capacity();
    }

    if (tslot != null && tslot != undefined) {
      this.game.units.remove(unit);
      unit.remove();
      var transport = this.game.unit_at(tx, ty);

      if (tslot >= transport.loaded_units.size) {
        transport.loaded_units.push(unit);
      } else {
        transport.loaded_units.splice(tslot, 0, unit);
      }
      transport.set_transport_capacity();
      unit.face_right();
      unit.x = tx;
      unit.y = ty;
    } else {
      unit.set_position(tx, ty);
    }

    for (var i = 0; i < unit.loaded_units.length; i++) {
      unit.loaded_units[i].set_position(unit.x, unit.y);
      unit.loaded_units[i].face_right();
    }
  },

  unexecute_move_unit: function(fx, fy, fslot, tx, ty, tslot) {
    this.execute_move_unit(tx, ty, tslot, fx, fy, fslot);
  },

  execute_modify_skip_count: function(player_num, val, old_val) {
    this.game.player_skips[player_num - 1] = val;
  },

  unexecute_modify_skip_count: function(player_num, val, old_val) {
    this.game.player_skips[player_num - 1] = old_val;
  },

  execute_defeat_player: function(player_num) {
    this.game.defeated_players.push(this.game.player_by_number(player_num));
  },

  unexecute_defeat_player: function(player_num) {
    var player = this.game.player_by_number(player_num);
    var idx = null;

    for (var i = 0; i < this.game.defeated_players.length; i++) {
      if (this.game.defeated_players[i].equals(player)) {
        var idx = i;
        break;
      }
    }

    this.game.defeated_players.splice(idx, 1);
  },

  _set_attribute: function(obj, attr, val) {
    if (obj['set_' + attr]) {
      obj['set_' + attr](val);
    } else {
      obj[attr] = val;
    }
  }
});
