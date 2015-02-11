var Game = new JS.Class({
  initialize: function(map_id, game_data) {
    this.id = game_data._id;
    this.map_id = game_data.map_id;
    this.name = game_data.name;
    this.starting_player_count = game_data.starting_player_count;
    this.status = game_data.status;
    this.turns_played = game_data.turns_played;
    this.rounds_played = game_data.rounds_played;
    this.chat_log = game_data.chat_log;
    this.preview_img = game_data.preview_img;
    this.type = game_data.type;
    this.new_player = game_data.new_player;

    this.players = [];
    for (var i in game_data.users) {
      this.players.push(new User(game_data.users[i]));
    }

    this._player_credits = game_data.player_credits;
    this.player_peace_offers = game_data.player_peace_offers;
    this.player_skips = game_data.player_skips;

    this.defeated_players = [];
    for (var i in game_data.defeated_users) {
      this.defeated_players.push(new User(game_data.defeated_users[i]));
    }

    this.winner = game_data.winner_user ? new User(game_data.winner_user) : null;

    this.map = new Map(map_id, game_data.map_tiles);
    this.map.draw();

    this.bases = new JS.Set([]);
    for (var i in game_data.bases) {
      var b = new Base(game_data.bases[i]);
      this.bases.add(b);
      b.add_to_map(this.map, b.x, b.y);
    }

    this.units = new JS.Set([]);
    for (var i in game_data.units) {
      var u = new Unit(game_data.units[i]);
      this.units.add(u);
      u.add_to_map(this.map, u.x, u.y);
    }

    this.terrain_modifiers = [];
    for (var i in game_data.terrain_modifiers) {
      var t = new TerrainModifier(game_data.terrain_modifiers[i]);
      this.add_terrain_modifier(t);
    }

    this.paged_command_history = {};
    for (var i in game_data.paged_command_history) {
      this.paged_command_history[i] = [];
      for (var j in game_data.paged_command_history[i]) {
        this.paged_command_history[i].push(this.new_game_command_for_game_from_json(game_data.paged_command_history[i][j]));
      }
    }
    this.last_command_page = game_data.last_command_page;
    this.command_page = this.last_command_page;

    if (this.command_page == -1) {
      this.command_page = 0;
      this.last_command_page = 0;
      this.paged_command_history[0] = [];
    }

    this.command_idx = this.paged_command_history[this.command_page].length - 1;

    this.player_subscriptions = game_data.player_subscriptions;
    this.time_limit = game_data.time_limit;

    this.turn_started_at = new Date();
    this.turn_started_at.setTime(game_data.turn_started_at * 1000);

    this.reminder_sent_at = new Date();
    this.reminder_sent_at.setTime(game_data.reminder_sent_at * 1000);
  },

  reset: function(callback) {
    var me = this;
    var game_loaded = false;
    var commands_loaded = false;
    var attempt_callback = function() {
      if (game_loaded && commands_loaded && callback) {
        callback();
      }
    }

    $.get('/maps/' + this.map_id + '.json', function(initial_map) {
      me.status = 'started';
      me.turns_played = 0;
      me.rounds_played = 0;

      me.defeated_players = [];
      me.winner = null;

      me._player_credits = [];
      for (var i = 1; i <= me.starting_player_count; i++) {
        me._player_credits[i] = me.map.starting_player_credits;
      }

      me.player_peace_offers = [];
      for (var i = 1; i <= me.starting_player_count; i++) {
        me.player_peace_offers.push(false);
      }

      me.player_skips = [];
      for (var i = 1; i <= me.starting_player_count; i++) {
        me.player_skips.push(0);
      }

      me.bases.forEach(function(b) { b.remove(); });
      me.bases = new JS.Set([]);
      for (var i in initial_map.bases) {
        var raw = initial_map.bases[i];
        var p = me.players[raw.player - 1];
        if (p) raw.player_id = p.id;

        var b = new Base(raw);
        me.bases.add(b);
        b.add_to_map(me.map, b.x, b.y);

        if (b.player == 1) { me._player_credits[0] += 200; }
      }

      me.units.forEach(function(u) { u.remove(); });
      me.units = new JS.Set([]);
      for (var i in initial_map.units) {
        var raw = initial_map.units[i];
        var p = me.players[raw.player - 1];
        if (p) raw.player_id = p.id;

        var u = new Unit(raw);
        me.units.add(u);
        u.add_to_map(me.map, u.x, u.y);
      }

      for (var i in me.terrain_modifiers) { me.terrain_modifiers[i].remove(); };
      me.terrain_modifiers = [];
      for (var i in initial_map.terrain_modifiers) {
        var raw = initial_map.terrain_modifiers[i];
        var tm = new TerrainModifier(raw);
        me.add_terrain_modifier(tm);
      }

      game_loaded = true;
      attempt_callback();
    });

    this.load_command_history_page(0, function() {
      me.command_idx = -1;
      me.command_page = 0;
      commands_loaded = true;
      attempt_callback();
    });
  },

  load_command_history_page: function(page, callback) {
    var me = this;

    if (!this.paged_command_history[page]) {
      $.get('/games/' + this.id + '/command_history.json', { 'page': page }, function(cmds) {
        me.paged_command_history[page] = [];

        for (var i in cmds.commands) {
          me.paged_command_history[page].push(me.new_game_command_for_game_from_json(cmds.commands[i]));
        }

        if (callback) callback();
      });
    } else {
      if (callback) callback();
    }
  },

  last_executed_command: function() {
    if (this.last_command_page == -1) return null;

    if (this.command_idx > -1) {
      return this.paged_command_history[this.command_page][this.command_idx];
    } else {
      if (this.command_page > 0) {
        var page = this.paged_command_history[this.command_page - 1];
        return page[page.length - 1];
      } else {
        return null;
      }
    }
  },

  pop_last_command: function() {
    if (this.command_idx == 0) {
      var ret = this.paged_command_history[this.last_command_page][0];

      if (this.last_command_page > 0) {
        this.paged_command_history[this.last_command_page] = null;
        this.command_page -= 1;
        this.last_command_page -= 1;
        this.command_idx = 19;
      } else {
        this.command_page -= 1;
        this.last_command_page -= 1;
        this.command_idx = -1;
      }

      return ret;
    } else {
      this.command_idx -= 1;
      return this.paged_command_history[this.last_command_page].pop();
    }
  },

  push_command: function(cmd) {
    if (this.last_command_page == -1) {
      this.last_command_page = 0;
      this.command_page = 0;
      this.paged_command_history[0] = [];
    }

    if (this.paged_command_history[this.last_command_page].length < 20) {
      this.paged_command_history[this.last_command_page].push(cmd);
      this.command_idx += 1;
    } else {
      this.last_command_page += 1;
      this.paged_command_history[this.last_command_page] = [];
      this.paged_command_history[this.last_command_page].push(cmd);
      this.command_idx = 0;
      this.command_page += 1;
    }
  },

  executed_last_command: function() {
    return (this.command_page == this.last_command_page && this.command_idx == this.paged_command_history[this.command_page].length - 1);
  },

  rewind: function(callback) {
    this.paged_command_history[this.command_page][this.command_idx].unexecute();
    this.command_idx -= 1;
    var me = this;

    if (this.command_idx < 0 && this.command_page > 0) {
      this.load_command_history_page(this.command_page - 1, function() {
        me.command_page -= 1;
        me.command_idx = me.paged_command_history[me.command_page].length - 1;
        if (callback) callback();
      });
    } else {
      if (callback) callback();
    }
  },

  rewind_until: function(until, callback) {
    var me = this;

    this.rewind(function() {
      if (!until() && me.last_executed_command()) {
        me.rewind_until(until, callback);
      } else {
        if (callback) callback();
      }
    });
  },

  fast_forward: function(callback) {
    this.command_idx += 1;
    var me = this;

    if (this.command_idx > this.paged_command_history[this.command_page].length - 1 && this.command_page < this.last_command_page) {
      this.load_command_history_page(this.command_page + 1, function() {
        me.command_idx = 0;
        me.command_page += 1;
        me.paged_command_history[me.command_page][me.command_idx].replay();
        if (callback) callback();
      });
    } else {
      this.paged_command_history[this.command_page][this.command_idx].replay();
      if (callback) callback();
    }
  },

  rewind_to_beginning: function(callback) {
    this.reset(callback);
  },

  rewind_to_last_round: function(callback) {
    var this_user = this.current_user();
    var this_round = this.rounds_played;
    if (this.status != 'started') this_round -= 1;
    var me = this;

    this.rewind_until(function() {
      return me.rounds_played < this_round && this_user.equals(me.current_user());
    }, callback);
  },

  step_backward: function(callback) {
    this.rewind(callback);
    return (this.command_page > 0 || this.command_idx > -1);
  },

  step_forward: function(callback) {
    this.fast_forward(callback);
    return (this.command_page < this.last_command_page || this.command_idx < this.paged_command_history[this.command_page].length - 1);
  },

  new_game_command_for_game_from_json: function(command_json) {
    var user = null;
    for (var j in this.players) {
      if (this.players[j].id == command_json.user_id) {
        user = this.players[j];
        break;
      }
    }

    return GameCommand.new_from_json(command_json, this, user);
  },

  current_user: function() {
    return this.players[this.turns_played % this.starting_player_count];
  },

  current_user_idx: function() {
    return (this.turns_played % this.starting_player_count) + 1;
  },

  user_idx: function(user) {
    for (var i = 0; i < this.players.length; i++) {
      if (this.players[i].id == user.id) {
        return i + 1;
      }
    }
  },

  add_player: function(u) {
    this.units.forEach(function(unit) {
      if (unit.player == this.players.length + 1) {
        unit.player_id = u.id;
      }
    }, this);

    this.bases.forEach(function(base) {
      if (base.player == this.players.length + 1) {
        base.player_id = u.id;
      }
    }, this);

    this.players.push(u);
  },

  unit_at: function(x, y, slot) {
    var u = this.units.find(function(unit) {
      return unit.x == x && unit.y == y;
    });

    if (slot != null) {
      return u.loaded_units[slot];
    } else {
      return u;
    }
  },

  friendly_unit_at: function(player, x, y) {
    var u = this.unit_at(x, y);

    if (u && u.player_id == player.id) {
      return u;
    } else {
      return false;
    }
  },

  enemy_units: function(player) {
    return new JS.Set(
      this.units.select(function(u) {
        return u.player_id != player.id;
      })
    );
  },

  base_at: function(x, y) {
    return this.bases.find(function(base) {
      return base.x == x && base.y == y;
    });
  },

  friendly_base_at: function(player, x, y) {
    var u = this.base_at(x, y);

    if (u && u.player_id == player.id) {
      return u;
    } else {
      return false;
    }
  },

  terrain_at: function(x, y) {
    var t = null;
    for (var i = this.terrain_modifiers.length - 1; i >= 0; i--) {
      var it = this.terrain_modifiers[i];
      if (it.x == x && it.y == y) {
        t = it;
        break;
      }
    }

    if (t) {
      return t.terrain_name;
    } else {
      return GameConfig.tiles[this.map.tile_index(x, y)];
    }
  },

  unmodified_terrain_at: function(x, y) {
    return GameConfig.tiles[this.map.tile_index(x, y)];
  },

  terrain_modifier_at: function(x, y) {
    for (var i = this.terrain_modifiers.length - 1; i >= 0; i--) {
      var it = this.terrain_modifiers[i];
      if (it.x == x && it.y == y) {
        return it;
      }
    }
  },

  add_terrain_modifier: function(t) {
    this.terrain_modifiers.push(t);
    t.add_to_map(this.map);
    this.update_modifiers_at(t.x, t.y);
  },

  remove_terrain_modifier: function(t) {
    for (var i in this.terrain_modifiers) {
      var tm = this.terrain_modifiers[i];
      if (tm.x == t.x && tm.y == t.y && tm.terrain_name == t.terrain_name) {
        this.terrain_modifiers.splice(i, 1);
        break;
      }
    }
    t.remove();
    this.update_modifiers_at(t.x, t.y);
  },

  update_modifiers_at: function(x, y) {
    this.update_terrain_modifier_for_surrounding_terrain(x, y);

    var surrounding = PathFinder.surrounding_tiles(new HCoordinate(x, y));
    for (var i in surrounding) {
      this.update_terrain_modifier_for_surrounding_terrain(surrounding[i].x, surrounding[i].y);
    }
  },

  update_terrain_modifier_for_surrounding_terrain: function(x, y) {
    var tm = this.terrain_modifier_at(x, y);
    if (tm) {
      var terrains = [];

      var surrounding = PathFinder.surrounding_tiles(new HCoordinate(x, y));
      for (var i in surrounding) {
        terrains.push(this.terrain_at(surrounding[i].x, surrounding[i].y));
      }

      tm.update_for_surrounding_terrain(terrains);
    }
  },

  can_build_bridge_at: function(x, y) {
    if ($.inArray(this.terrain_at(x, y), ['shallow_water', 'ford']) == -1) {
      return false;
    }

    var terrains = [];

    var surrounding = PathFinder.surrounding_tiles(new HCoordinate(x, y));
    for (var i in surrounding) {
      terrains.push(this.terrain_at(surrounding[i].x, surrounding[i].y));
    }

    return TmBridgeSprite.bridge_type_within(terrains) != null;
  },

  players_include: function(player) {
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        return true;
      }
    }

    return false;
  },

  defeated_players_include: function(player) {
    for (var i in this.defeated_players) {
      if (this.defeated_players[i].equals(player)) {
        return true;
      }
    }

    return false;
  },

  player_base_count: function(player) {
    return this.bases.select(function(base) {
      return base.player_id == player.id && base.base_type == 'Base';
    }, this).length;
  },

  player_credits: function(player) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    return this._player_credits[idx];
  },

  player_offered_peace: function(player) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    return this.player_peace_offers[idx];
  },

  player_skip_count: function(player) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    return this.player_skips[idx];
  },

  increment_player_skip_count: function(player) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    this.player_skips[idx] += 1;
  },

  reset_player_skip_count: function(player) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    this.player_skips[idx] = 0;
  },

  modify_player_credits: function(player, amt) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    this._player_credits[idx] += amt;
  },

  set_player_num_credits: function(player_num, amt) {
    this._player_credits[player_num - 1] = amt;
  },

  update_player_peace_offer: function(player, status) {
    var idx = 0;
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        idx = i; break;
      }
    }

    this.player_peace_offers[idx] = status;
  },

  modify_player_idx_credits: function(idx, amt) {
    this._player_credits[idx] += amt;
  },

  player_by_id: function(id) {
    for (var i in this.players) {
      if (this.players[i].id == id) return this.players[i];
    }
  },

  player_number: function(player) {
    for (var i in this.players) {
      if (this.players[i].equals(player)) {
        return parseInt(i) + 1;
      }
    }
  },

  player_by_number: function(player) {
    return this.players[player - 1];
  },

  can_undo: function() {
    if (this.last_command_page == -1) return false;

    if (this.paged_command_history[this.last_command_page].length > 0) {
      var last_command = this.last_executed_command();
      return last_command.can_undo();
    }

    return false;
  },

  over_time: function() {
    return this.can_skip();
  },

  can_skip: function() {
    var now = new Date().getTime();

    if (this.status == 'started' && this.current_user()) {
      if (this.turn_started_at == null || now - this.turn_started_at >= this.time_limit * 1000) {
        return true;
      }
    }

    return false;
  },

  can_send_reminder: function() {
    var now = new Date().getTime();

    if (this.can_skip()) {
      if (this.reminder_sent_at == null || now - this.reminder_sent_at >= this.time_limit * 1000) {
        return true;
      }
    }

    return false;
  }
});
