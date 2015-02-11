var GameCommand = new JS.Class({
  initialize: function(game, user, params) {
    this.game = game;
    this.user = user;
    this.params = params;
    this.executed = false;
    this.committed = false;
    this.changes = [];
  },

  execute: function() {
    throw new Error('Called abstract method GameCommand#execute');
  },

  post_commit: function(data) {
    this.finish();
  },

  finish: function(data) {
    // No-op
  },

  execute_and_commit: function() {
    this.execute();
    this.commit();
  },

  replay: function() {
    var spcl = new SpclInterpreter(this.game);

    for (var i = 0; i < this.changes.length; i++) {
      spcl.execute(this.changes[i]);
    }
  },

  unexecute: function() {
    var spcl = new SpclInterpreter(this.game);

    for (var i = this.changes.length; i--; i >= 0) {
      spcl.unexecute(this.changes[i]);
    }
  },

  commit: function(callback_object, callback) {
    var p = this.params;
    var me = this;
    p.command = this.class_name();

    $.post('/games/' + this.game.id + '/execute_command', this.params, function(data) {
      me.post_commit(data);

      if (callback_object && callback) {
        callback_object[callback]();
      }
    });
  },

  modify: function(obj, attr, val) {
    var type = (obj.klass == Unit ? 'unit' : 'base')
    var old_val = obj[attr];
    this.push_change(['modify', type, obj.x, obj.y, attr, val, old_val]);
  },

  modify_loaded_unit: function(transport, obj, attr, val) {
    var old_val = obj[attr];

    var idx;
    for (var i = 0; i < transport.loaded_units.length; i++) {
      if (transport.loaded_units[i].equals(obj)) {
        idx = i;
        break;
      }
    }

    this.push_change(['modify_loaded_unit', transport.x, transport.y, idx, attr, val, old_val]);
  },

  modify_game: function(attr, val) {
    var old_val = this.game[attr];
    this.push_change(['modify_game', attr, val, old_val]);
  },

  modify_credits: function(player_num, val) {
    var old_val = this.game._player_credits[player_num - 1];
    this.push_change(['modify_credits', player_num, val, old_val]);
  },

  create_unit: function(user, unit_type, x, y) {
    var player_num = this.game.player_number(user);
    this.push_change(['create_unit', player_num, user.id, unit_type, x, y]);
  },

  destroy_unit: function(unit) {
    this.push_change(['destroy_unit', unit.x, unit.y, unit.to_json()]);
  },

  create_terrain_modifier: function(tm, x, y) {
    this.push_change(['create_terrain_modifier', tm, x, y]);
  },

  destroy_terrain_modifier: function(tm) {
    this.push_change(['destroy_terrain_modifier', tm.x, tm.y, tm.to_json()]);
  },

  move_unit: function(fx, fy, fslot, tx, ty, tslot) {
    this.push_change(['move_unit', fx, fy, fslot, tx, ty, tslot]);
  },

  modify_skip_count: function(user, val) {
    var player_num = this.game.player_number(user);
    var old_val = this.game.player_skip_count(user);
    this.push_change(['modify_skip_count', player_num, val, old_val]);
  },

  defeat_user: function(user) {
    var player_num = this.game.player_number(user);
    this.push_change(['defeat_player', player_num]);
  },

  start_capture: function(base, user) {
    this.modify(base, 'capture_player_id', user.id);
    this.modify(base, 'capture_player', this.game.player_number(user));
    this.modify(base, 'capture_phase', 1);
  },

  continue_capture: function(base, user) {
    this.modify(base, 'capture_phase', base.capture_phase - 1);

    if (base.capture_phase < 0) {
      this.modify(base, 'player_id', base.capture_player_id);
      this.modify(base, 'player', base.capture_player);
      this.modify(base, 'capture_phase', null);
      this.modify(base, 'capture_player_id', null);
      this.modify(base, 'capture_player', null);
      return true;
    } else {
      return false;
    }
  },

  cancel_capture: function(base) {
    this.modify(base, 'capture_phase', null);
    this.modify(base, 'capture_player_id', null);
    this.modify(base, 'capture_player', null);
  },

  push_change: function(change) {
    var spcl = new SpclInterpreter(this.game);
    spcl.execute(change);

    this.changes.push(change);
  },

  load_ivars: function(json) {
    var exclude = ['user_id', 'params', 'command_class'];
    for (var i in json.ivars) {
      if ($.inArray(i, exclude) == -1) {
        eval('this.' + i + ' = json.ivars[i];');
      }
    }
  },

  extend: {
    new_from_json: function(json, game, user) {
      var ret = null;

      if (json.command_class == 'CompositeGameCommand') {
        ret = CompositeGameCommand.new_from_json(json, game, user);
      } else {
        ret = eval('new ' + json.command_class + '(game, user, json.params);');
      }

      ret.load_ivars(json);
      ret.changes = json.changes;

      return ret;
    }
  },

  can_undo: function() {
    return false;
  }
});
