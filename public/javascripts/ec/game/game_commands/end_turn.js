var EndTurn = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
    this.surrender = params.surrender;
    this.skipping = params.skipping;
  },

  class_name: function() {
    return 'EndTurn';
  },

  execute: function() {
    if (!this.skipping) {
      this.modify_skip_count(this.user, 0);
    }

    this.reset_units();
    this.cull_defeated_players();
    this.advance_turn();
    this.setup_new_turn();
  },

  cull_defeated_players: function() {
    var defeated_players = new JS.Set([]);

    if (this.surrender) defeated_players.add(this.user);

    new JS.Set(this.game.players).forEach(function(u) {
      var remaining_base_count = 0;
      var remaining_unit_count = 0;

      this.game.bases.forEach(function(b) {
        if (b.player_id == u.id) {
          var unit = this.game.unit_at(b.x, b.y);

          if (!unit || unit.player_id == u.id) {
            remaining_base_count += 1;
          }
        }
      }, this);

      this.game.units.forEach(function(unit) {
        if (unit.player_id == u.id) {
          remaining_unit_count += 1;
        }
      }, this);

      if (remaining_base_count == 0 && remaining_unit_count == 0) {
        defeated_players.add(u);
      }
    }, this);

    defeated_players.forEach(function(user) {
      this.defeat_user(user);
    }, this);

    var remaining_players = new JS.Set([]);
    for (var i in this.game.players) {
      if (!this.game.defeated_players_include(this.game.players[i])) {
        remaining_players.add(this.game.players[i]);
      }
    }

    if (remaining_players.size == 1 && this.game.players.length > 1) {
      this.modify_game('status', 'win');
      this.modify_game('winner', remaining_players.first());
    } else if (remaining_players.size == 0) {
      this.modify_game('status', 'draw');
    } else if (remaining_players.all(function(p) { return this.game.player_offered_peace(p) }, this)) {
      this.modify_game('status', 'draw');
    }
  },

  reset_units: function() {
    var delete_units = [];

    this.game.units.forEach(function(u) {
      this.modify(u, 'flank_penalty', 0);
      this.modify(u, 'summoning_sickness', false);

      var base = this.game.base_at(u.x, u.y);

      if (!(base && base.capture_phase != null)) {
        if (!(u.build_phase && u.build_phase > -1)) {
          this.modify(u, 'movement_points', u.def.movement_points);
          this.modify(u, 'attacks', 0);
          this.modify(u, 'attacked', false);
          this.modify(u, 'healed', false);
          this.modify(u, 'moved', false);
        }
      }

      if (u.def.armor_type == 'air' && base) {
        if (base.player > 0 && base.player != u.player) {
          delete_units.push(u);
        }
      }

      for (var i in u.loaded_units) {
        var lu = u.loaded_units[i];
        this.modify_loaded_unit(u, lu, 'flank_penalty', 0);
        this.modify_loaded_unit(u, lu, 'movement_points', lu.def.movement_points);
        this.modify_loaded_unit(u, lu, 'attacks', 0);
        this.modify_loaded_unit(u, lu, 'attacked', false);
        this.modify_loaded_unit(u, lu, 'healed', false);
        this.modify_loaded_unit(u, lu, 'moved', false);
      }
    }, this);

    for (var i in delete_units) {
      this.destroy_unit(delete_units[i]);
    }
  },

  advance_turn: function() {
    while (true) {
      this.modify_game('turns_played', this.game.turns_played + 1);
      if (this.game.turns_played % this.game.starting_player_count == 0) {
        this.modify_game('rounds_played', this.game.rounds_played + 1);
      }

      if (this.game.current_user() == null || this.game.status == 'draw') break;
      if (!this.game.defeated_players_include(this.game.current_user())) break;
    }
  },

  setup_new_turn: function() {
    var player_idx = this.game.turns_played % this.game.starting_player_count;

    var base_count = 0;
    this.game.bases.forEach(function(b) {
      if (b.base_type == 'Base' && b.player == player_idx + 1) {
        base_count += 1;
      }
    }, this);
    var new_credits_amount = this.game._player_credits[player_idx] + (base_count * 200);

    this.modify_credits(player_idx + 1, new_credits_amount);

    if (this.game.current_user()) {
      this.game.bases.forEach(function(b) {
        if (b.capture_player_id == this.game.current_user().id) {
          var captured = this.continue_capture(b);

          if (captured) {
            var unit = this.game.unit_at(b.x, b.y);
            this.destroy_unit(unit);
          }
        }
      }, this);

      this.game.units.forEach(function(u) {
        if (typeof(u.build_phase) == 'number' && u.build_phase > -1 && u.player_id == this.game.current_user().id) {
          this.modify(u, 'build_phase', u.build_phase - 1);

          if (u.build_phase < 0) {
            var building = u.current_build;

            this.modify(u, 'build_phase', null);
            this.modify(u, 'current_build', null);
            this.modify(u, 'movement_points', u.def.movement_points);
            this.modify(u, 'attacks', 0);
            this.modify(u, 'attacked', false);
            this.modify(u, 'healed', false);
            this.modify(u, 'moved', false);

            if (building == 'destroy') {
              this.destroy_terrain_modifier(this.game.terrain_modifier_at(u.x, u.y))
            } else {
              this.create_terrain_modifier(building, u.x, u.y);
            }
          }
        }
      }, this);
    }

    this.modify_game('turn_started_at', new Date());
  },
});
