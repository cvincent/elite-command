var ReticuleLayer = 5;

var GameController = new JS.Class({
  include: JS.State,

  initialize: function(map_id, game_json, user_json) {
    this.game = new Game(map_id, game_json);
    this.user = new User(user_json);

    this.current_command = new CompositeGameCommand(this.game, this.user, {});

    this.map = this.game.map;
    this.map.set_event_handler(this);

    this.selected_unit = null;
    this.targeted_unit = null;
    this.selected_unit_slot = null;
    this.selected_base = null;
    this.targeted_base = null;
    this.actionable_tiles = new JS.Hash(null);

    this.selection_reticule = null;
    this.target_reticules = new JS.Set([]);
    this.transport_reticules = new JS.Set([]);
    this.heal_reticules = new JS.Set([]);

    this.rp_playing = false;

    this.dialog = null;

    this.setState('Waiting');

    this.update_view_for_game_state();

    $('#loading_splash').fadeOut();
  },
  
  current_user_playing: function() {
    return this.user && this.game.current_user() && this.user.equals(this.game.current_user()) && this.game.status == 'started';
  },

  tile_click: function(x, y) {
    if (this.current_user_playing()) {
      var u;

      if (this.selected_unit && x == this.selected_unit.x && y == this.selected_unit.y) {
        // Override in case a loaded unit is selected
        u = this.selected_unit;
      } else {
        u = this.game.unit_at(x, y);
      }

      var b = this.game.base_at(x, y);
      var action = this.actionability_at(x, y);

      if (u && u == this.selected_unit) {
        this.clicked_selected_unit(u);
      } else if (action) {
        this.clicked_actionable_tile(x, y, action);
      } else if (u && u.player_id == this.user.id) {
        this.clicked_friendly_unit(u);
      // } else if (u) {
      //   this.clicked_rival_unit(u);
      } else if (b && b.player_id == this.user.id) {
        this.clicked_friendly_base(b);
      } else {
        this.clicked_tile(x, y);
      }
    }
  },

  tile_mousemove: function(x, y) {
    var u = this.game.unit_at(x, y);
    var b = this.game.base_at(x, y);
    var a = this.actionability_at(x, y);
    var r = this.reticule_at(x, y);

    if ((this.user && this.user.equals(this.game.current_user())) && ((u && u.player_id == this.user.id) || (b && b.player_id == this.user.id) || a || r)) {
      $('body').css('cursor', 'pointer');
    } else {
      $('body').css('cursor', 'default');
    }
  },

  end_turn: function() {
    if (this.current_user_playing()) {
      var end_turn = new EndTurn(this.game, this.user, { surrender: false });
      this.current_command.add_and_execute_command(end_turn);
      this.commit_and_reset_command();

      this.disable_all();
      $('#spinner').show();
      this.setState('WaitingForAjax');

      window.GameAlerts.remove_alerts_for_game_id(this.game.id);

      this.check_first_game_end_status();

      if (this.game.current_user() == null) {
        show_invite_dialog(true);
      }
    }
  },

  fullscreen: function() {
    $('#status').toggleClass('fullscreen');
    $('#fullscreen_bottom_plate').toggleClass('fullscreen');
    $('#player_options').toggleClass('fullscreen');
    $('#main_unit_options').toggleClass('fullscreen');
    $('#building_buttons').toggleClass('fullscreen');
    $('#replay_buttons').toggleClass('fullscreen');
    $('#over_time_options').toggleClass('fullscreen');
    $('#map').toggleClass('fullscreen');
    $('#map_event_catcher').toggleClass('fullscreen');
    $('#game_options').toggleClass('fullscreen');

    if (this.fullscreen_mode) {
      $('#game_options #fullscreen_opt').text('View Fullscreen');
      this.fullscreen_mode = false;
    } else {
      $('#game_options #fullscreen_opt').text('Leave Fullscreen');
      this.fullscreen_mode = true;

      $('body').keyup(function(e) {
        if (e.which == 27 && Controller.fullscreen_mode) {
          Controller.fullscreen();
        }
      });
    }
  },

  replay: function(last_round) {
    this.setState('Replaying');
    $('#replay_controls').slideDown();
    $('#replay_controls input').attr('disabled', true);
    $('#end_turn_button input').attr('disabled', true);
    $('#game_options .enter_rp').hide();
    $('#game_options').append('<li><a href="#" onclick="Controller.rp_end(); return false;">End Replay</a></li>');

    var me = this;
    var callback = function() {
      me.set_replay_controls();
    }

    this.disable_replay_controls();

    if (last_round) {
      this.game.rewind_to_last_round(callback);
    } else {
      this.game.rewind_to_beginning(callback);
    }
  },

  rp_step_backward: function() {
    var me = this;

    this.disable_replay_controls();

    this.game.step_backward(function() {
      me.set_replay_controls();
    });
  },

  rp_step_forward: function() {
    var me = this;

    this.disable_replay_controls();

    this.game.step_forward(function() {
      me.set_replay_controls();
    });
  },

  rp_play: function() {
    if (this.rp_playing) {
      clearTimeout(this.play_timeout);
      this.rp_playing = false;
      this.set_replay_controls();
    } else {
      this.rp_playing = true;
      this.rp_play_next();
    }
  },

  rp_play_next: function() {
    var me = this;
    var callback = function() {
      me.set_replay_controls();

      if (!me.game.executed_last_command()) {
        me.play_timeout = setTimeout(function() {
          me.rp_play_next();
        }, 500);
      } else {
        me.rp_play();
      }
    }

    this.disable_replay_controls();
    this.game.step_forward(callback);
  },

  rp_end: function() {
    this.disable_replay_controls();
    location.reload();
  },

  disable_replay_controls: function() {
    $('#replay_spinner').show();
    $('#rp_rw').attr('disabled', true);
    $('#rp_pl').attr('disabled', true);
    $('#rp_ff').attr('disabled', true);
    $('#rp_end').attr('disabled', true);
  },

  set_replay_controls: function() {
    $('#replay_spinner').hide();

    if (!this.rp_playing) {
      if (this.game.last_executed_command()) {
        $('#rp_rw').attr('disabled', false);
      } else {
        $('#rp_rw').attr('disabled', true);
      }

      if (!this.game.executed_last_command()) {
        $('#rp_pl').attr('disabled', false);
        $('#rp_ff').attr('disabled', false);
      } else {
        $('#rp_pl').attr('disabled', true);
        $('#rp_ff').attr('disabled', true);
      }

      $('#rp_pl').val('\u00A0\u25B6');
      $('#rp_end').attr('disabled', false);
    } else {
      $('#rp_rw').attr('disabled', true);
      $('#rp_ff').attr('disabled', true);

      $('#rp_pl').val('\u00A0\u275A\u275A');
      $('#rp_pl').attr('disabled', false);
      $('#rp_end').attr('disabled', true);
    }
  },

  check_first_game_end_status: function() {
    if (this.game.players_include(this.user) && this.game.new_player) {
      if (this.game.status == 'win') {
        if (this.game.winner.equals(this.user)) {
          var BeatTomDialog = new JS.Class(Dialog, {
            initialize: function(game, user) {
              var me = this;
              this.callSuper();

              this.content.append('<h3>You won!</h3>');

              this.content.append("<p>You beat back TomServo's forces and are now the undisputed victor. Now you're ready to play against real human opponents. Here's what to do next:</p>");

              var actions = $('<ul></ul>');
              actions.append('<li><a href="/games/new">Start</a> or <a href="/games">join</a> a new game!</li>');
              actions.append('<li>Introduce yourself in the <a href="' + NEW_PLAYERS_FORUM_URL + '">New Players forum</a>!</li>');
              this.content.append(actions);

              this.content.append("<p>Keep in mind that games against humans are typically played at a slower pace, but are much more fun and challenging. Your opponent may not respond immediately. This is to be expected. If you want more of Elite Command, feel free to start several games at once!</p>");

              var buttons = $('<p style="text-align: right"></p>');
              var close = $('<button>Close</button>').click(function() { me.close(); });
              buttons.append(close);
              this.content.append(buttons);
            }
          });

          var d = new BeatTomDialog(this.game, this.user);
          d.open();
        } else {
          var LostToTomDialog = new JS.Class(Dialog, {
            initialize: function(game, user) {
              var me = this;
              this.callSuper();

              this.content.append('<h3>TomServo won!</h3>');

              this.content.append('<p>Somehow, Tom was able to maneuver his way to victory. Perhaps you\'d like to try again?</p>');

              var form = $('<form action="/games/new_player_join" method="post"></form>');
              form.append('<p style="text-align: center"><input type="hidden" name="game_join_source" value="tom_servo_rematch"/><input type="submit" value="Rematch" class="main"/></p>')
              this.content.append(form);
            }
          });

          var d = new LostToTomDialog(this.game, this.user);
          d.open();
        }
      }
    }
  },

  surrender: function() {
    if (this.current_user_playing()) {
      var surrender = new EndTurn(this.game, this.user, { surrender: true });
      this.current_command.add_and_execute_command(surrender);
      this.commit_and_reset_command();

      this.disable_all();
      $('#spinner').show();
      this.setState('WaitingForAjax');

      this.check_first_game_end_status();
    }
  },

  toggle_peace: function() {
    var me = this;

    if (this.current_user_playing()) {
      this.disable_all();
      $('#spinner').show();

      $.post('/games/' + this.game.id + '/toggle_peace', {}, function(data) {
        me.command_ajax_complete();
      });

      this.setState('WaitingForAjax');
    }
  },

  undo: function() {
    if (this.current_user_playing()) {
      var last_command = this.game.pop_last_command();
      if (last_command) {
        last_command.unexecute();
      }

      var me = this;

      $.post('/games/' + this.game.id + '/unexecute_last_command', {}, function(date) {
        me.command_ajax_complete();
      });

      this.disable_all();
      $('#spinner').show();
      this.setState('WaitingForAjax');
    }
  },

  send_reminder: function() {
    var remind_player = new RemindPlayer(this.game, this.user);
    this.current_command.add_and_execute_command(remind_player);
    this.commit_and_reset_command();

    this.disable_all();
    $('#spinner').show();
    this.setState('WaitingForAjax');

    window.GameAlerts.remove_alerts_for_game_id(this.game.id);
  },

  skip: function() {
    var skip_player = new SkipPlayer(this.game, this.user);
    this.current_command.add_and_execute_command(skip_player);
    this.commit_and_reset_command();

    this.disable_all();
    $('#spinner').show();
    this.setState('WaitingForAjax');

    window.GameAlerts.remove_alerts_for_game_id(this.game.id);
  },

  force_surrender: function() {
    var force_surrender = new ForceSurrender(this.game, this.user);
    this.current_command.add_and_execute_command(force_surrender);
    this.commit_and_reset_command();

    this.disable_all();
    $('#spinner').show();
    this.setState('WaitingForAjax');

    window.GameAlerts.remove_alerts_for_game_id(this.game.id);
  },

  received_execute_game_command: function(command_json) {
    var gc = this.game.new_game_command_for_game_from_json(command_json.cmd);
    if (!gc.user.equals(this.user)) {
      var game_state_before = this.game.status;

      gc.execute();
      gc.finish();
      this.game.push_command(gc);
      this.update_view_for_game_state();

      if (this.game.status != game_state_before) this.check_first_game_end_status();
    }
  },

  received_unexecute_game_command: function(command_json) {
    var gc = this.game.new_game_command_for_game_from_json(command_json.cmd);
    if (!gc.user.equals(this.user)) {
      gc.unexecute();
      this.game.pop_last_command();
      this.update_view_for_game_state();
    }
  },

  received_player_joined: function(msg) {
    var u = new User(msg.user);
    this.game.add_player(u);

    if (this.game.current_user().equals(u)) this.game.turn_started_at = new Date();
    this.chat_log.received_info_message(msg.info_message);
    this.update_view_for_game_state();
  },

  received_player_peace_treaty: function(msg) {
    var u = new User(msg.user);
    this.game.update_player_peace_offer(u, msg.status);
    this.chat_log.received_info_message(msg.info_message);
    this.update_view_for_game_state();
  },

  show_loaded_units: function() {
    this.disembark_unit = this.selected_unit;

    if (this.current_command.command_count() > 0) {
      this.commit_and_reset_command('stage_select_loaded_unit');
    } else {
      this.stage_select_loaded_unit();
    }
  },

  stage_select_loaded_unit: function() {
    this.dialog = new LoadedUnitsDialog(this.disembark_unit, this, 'chose_unit', 'chose_cancel');
    this.dialog.open();
    this.disable_all();
    this.deselect_unit();
    this.setState('StagedSelectLoadedUnit');
  },

  heal_unit: function() {
    var heal_unit = new HealUnit(this.game, this.user, {
      x: this.selected_unit.x, y: this.selected_unit.y
    });
    this.current_command.add_and_execute_command(heal_unit);
    this.commit_and_reset_command();

    this.deselect_unit();
    this.setState('WaitingForAjax');
  },

  scrap_unit: function() {
    var scrap_unit = new ScrapUnit(this.game, this.user, {
      x: this.selected_unit.x, y: this.selected_unit.y
    });
    this.current_command.add_and_execute_command(scrap_unit);
    this.commit_and_reset_command();

    this.deselect_unit();
    this.setState('WaitingForAjax');
  },

  clear_woods: function() {
    this.build('plains');
  },

  build_road: function() {
    this.build('road');
  },

  build_bridge: function() {
    this.build('bridge');
  },

  destroy_improvement: function() {
    this.build('destroy');
  },

  build: function(what) {
    this.dialog = new BuildDialog(
      what, this.selected_unit,
      this.game.player_credits(this.user),
      this, 'chose_confirm_build_' + what, 'chose_cancel'
    );
    this.dialog.open();

    this.setState('StagedBuild');
  },

  select_unit: function(u, slot) {
    var b = this.game.base_at(u.x, u.y);
    var capturing = (b && b.capture_phase != null)

    if (!capturing && (u.loaded_units.length > 0 || u.movement_points > 0 || u.attacks < u.def.attack_phases || (b && u.health < 10))) {
      this.deselect_unit();

      if (slot != undefined) this.selected_unit_slot = slot;

      this.selected_unit = u;
      this.create_selection_reticule(u.x, u.y);
      this.show_unit_options(u, b);
      this.actionize_and_highlight_possible_unit_destinations();

      if (this.selected_unit_slot == null) this.actionize_and_target_possible_unit_targets();
      if (this.selected_unit_slot == null) this.actionize_and_reticule_possible_transports();
      if (this.selected_unit_slot == null) this.actionize_and_reticule_possible_heal_targets();

      this.setState('UnitSelected');
      this.disable_all();
    }
  },

  select_base: function(b) {
    var u = this.game.unit_at(b.x, b.y);

    if (!u) {
      this.deselect_unit();
      this.selected_base = b;
      this.create_selection_reticule(b.x, b.y);

      this.dialog = new BuyUnitDialog(this.game, b, this, 'chose_unit_type', 'chose_cancel');
      this.dialog.open();
      this.setState('StagedBuyUnit');
      this.disable_all();
    }
  },

  deselect_unit: function() {
    if (this.selection_reticule) {
      this.selection_reticule.remove();
      this.selection_reticule = null;
    }

    if (this.fullscreen_mode) {
      $('#unit_options').hide();
    } else {
      $('#unit_options').slideUp();
    }

    this.selected_unit = null;
    this.selected_unit_slot = null;
    this.reset_actionability();
    this.unhighlight_tiles();
    this.remove_targets();
    this.remove_transport_reticules();
    this.remove_heal_reticules();
    this.setState('Waiting');
  },

  deselect_base: function() {
    if (this.selection_reticule) {
      this.selection_reticule.remove();
      this.selection_reticule = null;
    }

    this.selected_base = null;
    this.setState('Waiting');
  },

  show_unit_options: function(u, b) {
    if (this.fullscreen_mode) {
      $('#unit_options').show();
    } else {
      $('#unit_options').slideDown();
    }
    $('#unit_options span').hide();

    if (u.def.transport_capacity) {
      $('#disembark_button').show();

      if (u.loaded_units.length > 0) {
        $('#loaded_units_button').attr('disabled', false);
      } else {
        $('#loaded_units_button').attr('disabled', true);
      }
    }

    $('#heal_button').show();

    if (u.def.armor_type == 'personnel') $('#heal_unit_button').val('Heal');
    else $('#heal_unit_button').val('Repair');

    if (u.health < 10 && u.attacked == false && !u.healed && b && b.player_id == u.player_id && $.inArray(u.unit_type, GameConfig.bases[b.base_type].can_build) > -1) {
      $('#heal_unit_button').attr('disabled', false);
    } else {
      $('#heal_unit_button').attr('disabled', true);
    }

    $('#scrap_button').show();

    if (u.attacks == 0 && b && b.player_id == u.player_id && $.inArray(u.unit_type, GameConfig.bases[b.base_type].can_build) > -1 && u.loaded_units.length == 0) {
      $('#scrap_unit_button').attr('disabled', false);
    } else {
      $('#scrap_unit_button').attr('disabled', true);
    }

    if (u.def.can_build) {
      $('#building_buttons span').show();
      var t = this.game.terrain_at(u.x, u.y);

      $('#clear_woods_button').attr('disabled', !(t == 'woods' && u.def.can_build.plains));
      $('#build_road_button').attr('disabled', !($.inArray(t, ['plains', 'desert', 'tundra']) > -1 && u.def.can_build.road));
      $('#build_bridge_button').attr('disabled', !(this.game.can_build_bridge_at(u.x, u.y) && u.def.can_build.bridge));
      $('#destroy_improvement_button').attr('disabled', !($.inArray(t, ['road', 'bridge']) > -1 && u.def.can_build.destroy));
    }
  },

  create_selection_reticule: function(x, y) {
    this.selection_reticule = new Sprite(SpriteSheets.selection);
    this.selection_reticule.set_layer(ReticuleLayer);
    this.selection_reticule.add_to_map(this.map);
    this.selection_reticule.set_sprite(0, 0);
    this.selection_reticule.set_position(x, y);
    this.selection_reticule.e.addClass('no_shade');
  },

  commit_and_reset_command: function(callback) {
    var c = (callback ? callback : 'command_ajax_complete')
    this.current_command.commit(this, c);
    this.game.push_command(this.current_command);
    this.current_command = new CompositeGameCommand(this.game, this.user, {});
    this.disable_all();
    $('#spinner').show();
    this.setState('WaitingForAjax');
  },

  command_ajax_complete: function() {
    this.setState('Waiting');
    this.update_view_for_game_state();
  },

  states: {
    Waiting: {
      clicked_friendly_unit: function(u) {
        this.select_unit(u);
      },

      clicked_friendly_base: function(b) {
        this.select_base(b);
      }
    },

    UnitSelected: {
      clicked_actionable_tile: function(x, y, action) {
        if (action == 'move_unit') {
          if (this.current_command.command_count() > 0) {
            this.current_command.remove_and_unexecute_last_command();
          }

          var cmd = new MoveUnit(this.game, this.user, {
            unit_x: this.selected_unit.x, unit_y: this.selected_unit.y,
            unit_slot: this.selected_unit_slot,
            dest_x: x, dest_y: y
          });

          this.current_command.add_and_execute_command(cmd);

          this.show_unit_options(this.selected_unit, this.game.base_at(this.selected_unit.x, this.selected_unit.y));
          this.actionize_and_target_possible_unit_targets();
          this.actionize_and_reticule_possible_transports();
          this.actionize_and_reticule_possible_heal_targets();
        } else if (action == 'attack_unit') {
          this.targeted_unit = this.game.unit_at(x, y);

          this.dialog = new AttackDialog(
            this.selected_unit, this.targeted_unit, this.game, this.map,
            this, 'chose_confirm_attack', 'chose_cancel'
          );
          this.dialog.open();

          this.setState('StagedAttack');
        } else if (action == 'load_unit') {
          var cmd = new LoadUnit(this.game, this.user, {
            x: this.selected_unit.x, y: this.selected_unit.y, tx: x, ty: y
          });

          this.current_command.add_and_execute_command(cmd);
          this.deselect_unit();
          this.disable_all();
          $('#spinner').show();
          this.commit_and_reset_command();
          this.setState('WaitingForAjax');
        } else if (action == 'heal_unit') {
          var cmd = new FieldHealUnit(this.game, this.user, {
            x: this.selected_unit.x, y: this.selected_unit.y, tx: x, ty: y
          });

          this.current_command.add_and_execute_command(cmd);
          this.deselect_unit();
          this.disable_all();
          $('#spinner').show();
          this.commit_and_reset_command();
          this.setState('WaitingForAjax');
        } else {
          console.log(action);
        }
      },

      clicked_selected_unit: function(u) {
        // If the unit is on a base, stage base capture.
        // If the unit is staged, commit the command and reset the current command.
        // Either way, deselect the unit afterward.

        this.targeted_base = this.game.base_at(u.x, u.y);
        if (u.def.can_capture && this.targeted_base && this.user.id != this.targeted_base.player_id) {
          this.dialog = new CaptureBaseDialog(this, 'chose_confirm_capture', 'chose_wait', 'chose_cancel');
          this.dialog.open();

          this.setState('StagedCaptureBase');
        } else {
          if (this.current_command.command_count() > 0) {
            this.deselect_unit();
            this.disable_all();
            $('#spinner').show();
            this.commit_and_reset_command();
            this.setState('WaitingForAjax');
          } else {
            if (this.selected_unit_slot != null) {
              this.selected_unit.remove();
            }
            this.deselect_unit();
            this.update_view_for_game_state();
          }
        }
      },

      clicked_friendly_unit: function(u) {
        // Reset the current command unless it's empty, then select the other unit.

        if (this.current_command.command_count() > 0) {
          this.current_command.remove_and_unexecute_last_command();
        }

        if (this.selected_unit_slot != null) {
          this.selected_unit.remove();
        }

        if (u.x == this.selected_unit.x && u.y == this.selected_unit.y) {
          this.deselect_unit();
          this.update_view_for_game_state();
        } else {
          this.select_unit(u);
        }
      },

      clicked_friendly_base: function(b) {
        // Ignore as though it were an insignificant tile
        this.clicked_tile(b.x, b.y);
      },

      clicked_tile: function(x, y) {
        // Reset the current cmmand unless it's empty, then deselect.

        if (this.current_command.command_count() > 0) {
          this.current_command.remove_and_unexecute_last_command();
        }
        
        if (this.selected_unit_slot != null) {
          this.selected_unit.remove();
        }

        this.deselect_unit();
        this.update_view_for_game_state();
      }
    },

    StagedAttack: {
      chose_confirm_attack: function() {
        var attack = new Attack(this.game, this.user, {
          unit_x: this.selected_unit.x, unit_y: this.selected_unit.y,
          target_x: this.targeted_unit.x, target_y: this.targeted_unit.y
        });
        this.current_command.add_and_execute_command(attack);
        this.commit_and_reset_command();

        this.dialog.close();
        this.deselect_unit();
        this.setState('WaitingForAjax');
      },

      chose_cancel: function() {
        this.dialog.close();
        this.setState('UnitSelected');
      }
    },

    StagedCaptureBase: {
      chose_confirm_capture: function() {
        var capture = new CaptureBase(this.game, this.user, {
          x: this.targeted_base.x, y: this.targeted_base.y
        });
        this.current_command.add_and_execute_command(capture);
        this.commit_and_reset_command();

        this.dialog.close();
        this.deselect_unit();
        this.setState('WaitingForAjax');
      },

      chose_wait: function() {
        // If the unit is staged, commit it
        // If the unit is just selected, deselect it

        this.dialog.close();

        if (this.current_command.command_count() > 0) {
          this.commit_and_reset_command();
          this.deselect_unit();
          this.setState('WaitingForAjax');
        } else {
          this.deselect_unit();
          this.update_view_for_game_state();
        }
      },

      chose_cancel: function() {
        // If the unit is staged, unstage it, but leave it selected
        // If the unit is just selected, deselect it

        this.dialog.close();

        if (this.current_command.command_count() > 0) {
          this.current_command.remove_and_unexecute_last_command();
          this.setState('UnitSelected');
        } else {
          this.deselect_unit();
          this.update_view_for_game_state();
        }
      }
    },

    StagedBuild: {
      chose_confirm_build_plains: function() {
        this.chose_confirm_build('plains');
      },

      chose_confirm_build_road: function() {
        this.chose_confirm_build('road');
      },

      chose_confirm_build_bridge: function() {
        this.chose_confirm_build('bridge');
      },

      chose_confirm_build_destroy: function() {
        this.chose_confirm_build('destroy');
      },

      chose_confirm_build: function(what) {
        var cmd = new BeginBuilding(this.game, this.user, {
          x: this.selected_unit.x, y: this.selected_unit.y,
          building: what
        });
        this.current_command.add_and_execute_command(cmd);
        this.commit_and_reset_command();

        this.dialog.close();
        this.deselect_unit();
        this.setState('WaitingForAjax');
      },

      chose_cancel: function() {
        this.dialog.close();
        this.setState('UnitSelected');
      }
    },

    StagedBuyUnit: {
      chose_unit_type: function(unit_type) {
        var buy = new BuyUnit(this.game, this.user, {
          x: this.selected_base.x, y: this.selected_base.y,
          'unit_type': unit_type
        });
        this.current_command.add_and_execute_command(buy);
        this.commit_and_reset_command();

        this.dialog.close();
        this.deselect_unit();
        this.setState('WaitingForAjax');
      },

      chose_cancel: function() {
        this.dialog.close();
        this.deselect_base();
        this.update_view_for_game_state();
      }
    },

    StagedSelectLoadedUnit: {
      chose_unit: function(unit, slot) {
        this.dialog.close();
        unit.add_to_map(this.game.map)
        this.select_unit(unit, slot);
      },

      chose_cancel: function() {
        this.dialog.close();
        this.update_view_for_game_state();
        this.setState('Waiting');
      }
    },

    WaitingForAjax: {}
  },

  actionability_at: function(x, y) {
    return this.actionable_tiles.get(new HCoordinate(x, y));
  },

  set_actionability_at: function(x, y, action) {
    this.actionable_tiles.put(new HCoordinate(x, y), action);
  },

  reset_actionability: function() {
    this.actionable_tiles.clear();
  },

  reticule_at: function(x, y) {
    if (this.selection_reticule && this.selection_reticule.x == x && this.selection_reticule.y == y) {
      return this.selection_reticule;
    } else {
      var r = this.target_reticules.find(function(r) { return r.x == x && r.y == y });
      if (r) return r;

      r = this.transport_reticules.find(function(r) { return r.x == x && r.y == y });
      if (r) return r;

      r = this.heal_reticules.find(function(r) { return r.x == x && r.y == y });
      if (r) return r;

      return null;
    }
  },

  reset_actionability_type: function(type) {
    this.actionable_tiles.removeIf(function(pair) {
      return pair.value == type;
    }, this);
  },

  actionize_and_highlight_possible_unit_destinations: function() {
    var unit = this.selected_unit;
    var highlight_tiles = [];

    var cost_map = new JS.Hash(null);

    for (var x = 0; x < this.map.tiles_width; x++) {
      for (var y = 0; y < this.map.tiles_height; y++) {
        var coords = new HCoordinate(x, y);
        var cost = unit.terrain_cost(this.game.terrain_at(x, y), this.game.unmodified_terrain_at(x, y));
        cost_map.put(coords, cost);
      }
    }

    var pf = new PathFinder(cost_map, unit, this.game.enemy_units(this.user));
    var poss_dests = pf.possible_destination_tiles();
    var poss_unoccupied_dests = {};

    poss_dests.forEachPair(function(coord, rm_pts) {
      if (!this.game.unit_at(coord.x, coord.y)) {
        if (unit.def.armor_type != 'naval' || this.game.terrain_at(coord.x, coord.y) != 'bridge') {
          this.set_actionability_at(coord.x, coord.y, 'move_unit');
          highlight_tiles.push(coord);
        }
      }
    }, this);

    highlight_tiles.push(new HCoordinate(unit.x, unit.y));

    this.highlight_tiles(highlight_tiles);
  },

  highlight_tiles: function(tiles) {
    var no_shade_selector = '';

    for (var i in tiles) {
      var x = tiles[i].x;
      var y = tiles[i].y;

      if (no_shade_selector != '') no_shade_selector += ', '
      no_shade_selector += '#' + 'tile_x_' + x + '_y_' + y;

      var u = this.game.unit_at(x, y);
      if (u) no_shade_selector += ', ' + u.selector();

      var b = this.game.base_at(x, y);
      if (b) no_shade_selector += ', ' + b.selector();

      var tm = this.game.terrain_modifier_at(x, y);
      if (tm) no_shade_selector += ', #' + tm.sprite.e.attr('id');

      // Make sure selected loaded unit is included;
      // include selected unit no matter what
      no_shade_selector += ', ' + this.selected_unit.selector();
    }

    $(no_shade_selector).addClass('no_shade');

    this.map.e.addClass('shade');
  },

  unhighlight_tiles: function() {
    this.map.e.removeClass('shade');
    $('.no_shade').removeClass('no_shade');
  },

  actionize_and_target_possible_unit_targets: function() {
    var unit = this.selected_unit;
    this.remove_targets();

    if (unit.attacks < unit.def.attack_phases) {
      var range_cost_map = new JS.Hash(null);

      for (var x = 0; x < this.map.tiles_width; x++) {
        for (var y = 0; y < this.map.tiles_height; y++) {
          var coord = new HCoordinate(x, y);
          range_cost_map.put(coord, 1);
        }
      }

      var rf = new RangeFinder(range_cost_map, unit);
      var poss_targets = rf.possible_destination_tiles();
      var enemy_units = new JS.Set(this.game.enemy_units(this.user));

      poss_targets.removeIf(function(pair) {
        return !enemy_units.any(function(enemy_unit) {
          return enemy_unit.x == pair.key.x && enemy_unit.y == pair.key.y &&
            unit.def.attack[enemy_unit.def.armor_type] > 0;
        }, this);
      }, this);

      poss_targets.forEach(function(pair) {
        this.set_actionability_at(pair.key.x, pair.key.y, 'attack_unit');

        var t = new Sprite(SpriteSheets.target);
        t.set_layer(ReticuleLayer);
        t.add_to_map(this.map);
        t.set_sprite(0, 0);
        t.set_position(pair.key.x, pair.key.y);
        t.e.addClass('no_shade');
        this.target_reticules.add(t);

        $(this.game.unit_at(pair.key.x, pair.key.y).selector()).not('.no_shade')
          .addClass('no_shade').addClass('temp_no_shade');
      }, this);
    }
  },

  remove_targets: function() {
    this.target_reticules.forEach(function(ret) {
      $(this.game.unit_at(ret.x, ret.y).selector()).filter('.temp_no_shade')
        .removeClass('no_shade').removeClass('temp_no_shade');

      ret.remove();
    }, this);
    this.target_reticules.clear();

    this.reset_actionability_type('attack_unit');
  },

  actionize_and_reticule_possible_transports: function() {
    var unit = this.selected_unit;
    this.remove_transport_reticules();

    var tiles = PathFinder.surrounding_tiles(new HCoordinate(unit.x, unit.y));

    for (var i in tiles) {
      var transport = this.game.unit_at(tiles[i].x, tiles[i].y);

      if (transport && transport.can_load_unit(unit)) {
        this.set_actionability_at(transport.x, transport.y, 'load_unit');

        var t = new Sprite(SpriteSheets.friendly_target);
        t.set_layer(ReticuleLayer);
        t.add_to_map(this.map);
        t.set_sprite(0, 0);
        t.set_position(transport.x, transport.y);
        t.e.addClass('no_shade');
        this.transport_reticules.add(t);

        $(this.game.unit_at(transport.x, transport.y).selector()).not('.no_shade')
          .addClass('no_shade').addClass('temp_no_shade');
      }
    }
  },

  actionize_and_reticule_possible_heal_targets: function() {
    var unit = this.selected_unit;
    this.remove_heal_reticules();

    if (unit.def.can_heal) {
      var tiles = PathFinder.surrounding_tiles(new HCoordinate(unit.x, unit.y));

      for (var i in tiles) {
        var heal_target = this.game.unit_at(tiles[i].x, tiles[i].y);

        if (heal_target && unit.can_heal_unit(heal_target)) {
          this.set_actionability_at(heal_target.x, heal_target.y, 'heal_unit');

          var t = new Sprite(SpriteSheets.friendly_target);
          t.set_layer(ReticuleLayer);
          t.add_to_map(this.map);
          t.set_sprite(0, 0);
          t.set_position(heal_target.x, heal_target.y);
          t.e.addClass('no_shade');
          this.heal_reticules.add(t);

          $(heal_target.selector()).not('.no_shade')
          .addClass('no_shade').addClass('temp_no_shade');
        }
      }
    }
  },

  remove_transport_reticules: function() {
    this.transport_reticules.forEach(function(ret) {
      $(this.game.unit_at(ret.x, ret.y).selector()).filter('.temp_no_shade')
        .removeClass('no_shade').removeClass('temp_no_shade');

      ret.remove();
    }, this);
    this.transport_reticules.clear();

    this.reset_actionability_type('load_unit');
  },

  remove_heal_reticules: function() {
    this.heal_reticules.forEach(function(ret) {
      $(this.game.unit_at(ret.x, ret.y).selector()).filter('.temp_no_shade')
        .removeClass('no_shade').removeClass('temp_no_shade');

      ret.remove();
    }, this);
    this.heal_reticules.clear();

    this.reset_actionability_type('heal_unit');
  },

  update_view_for_game_state: function() {
    var current_player = this.game.current_user();

    this.game.units.forEach(function(u) {
      if (current_player && this.user && current_player.equals(this.user) && u.player_id == current_player.id) {
        u.movement_indicator.e.show();
        u.attacks_indicator.e.show();
      } else {
        u.movement_indicator.e.hide();
        u.attacks_indicator.e.hide();
      }
    }, this);

    $('#round_number').show().text('Round ' + (this.game.rounds_played + 1));

    if (this.game.status == 'win') {
      $('#game_status').show().text((this.game.winner.equals(this.user) ? 'You' : this.game.winner.username) + ' won!');
      $('#player_turn').hide();
    } else if (this.game.status == 'draw') {
      $('#game_status').show().text('Draw!');
      $('#player_turn').hide();
    } else if (this.game.status == 'started') {
      $('#player_turn').show();

      if (this.game.defeated_players_include(this.user)) {
        $('#game_status').show().text('You were defeated.');
      } else {
        $('#game_status').hide();
      }

      if (this.game.current_user()) {
        $('#player_turn')
          .attr('class', 'player_' + ((this.game.turns_played % this.game.starting_player_count) + 1))
          .text((this.game.current_user().equals(this.user) ? 'Your' : this.game.current_user().username + "'s") + ' turn');
      } else {
        $('#player_turn').attr('class', '').text('Waiting for another player...');
      }
    }

    if (this.game.players_include(this.user)) {
      $('#player_bases').show()
        .text('Your Bases: ' + this.game.player_base_count(this.user) + ' (200 credits per base)');
    } else {
      $('#player_bases').hide();
    }

    if (this.game.players_include(this.user)) {
      $('#player_credits').show()
        .text('Your Credits: ' + this.game.player_credits(this.user) + ' (+' + (200 * this.game.player_base_count(this.user)) + ' per turn)');
    } else {
      $('#player_credits').hide();
    }

    $('#game_time_limit').show().text(parseInt(this.game.time_limit / (60 * 60)) + '-hour time limit');

    if (this.game.players_include(this.user)) {
      $('#chat_field').attr('disabled', false);
    } else {
      $('#chat_field').attr('disabled', true);
    }

    $('.player_div').remove();

    var i = 0;
    for(var pi in this.game.players) {
      i++;
      var player = this.game.players[pi];
      var player_div = $('<div></div>');
      player_div.attr('class', 'player_div player_' + i);
      player_div.append($('<a href="/users/' + player.id + '">' + player.username + '</a>'));

      if (this.game.status == 'started' && this.game.current_user() && player.equals(this.game.current_user())) {
        player_div.addClass('current'); 
        player_div.append(' (<span id="turn_time"></span>)');
      }

      if (this.game.defeated_players_include(player)) {
        player_div.addClass('defeated');
      } else if (this.game.player_offered_peace(player)) {
        player_div.addClass('peace');
      }

      player_div.insertBefore('#player_options');
    }

    if (this.game.players.length == this.game.starting_player_count) {
      $('#invite_players_notice').slideUp();
    }

    if (this.current_user_playing()) {
      $('#player_options').show();
      $('#end_turn_button').show();
      $('#end_turn_button input').attr('disabled', false);
      $('#surrender_button input').show().attr('disabled', false);
      $('#toggle_peace_button input').show().attr('disabled', false);
      $('#toggle_peace_button input').val(this.game.player_offered_peace(this.user) ? 'Cancel Peace' : 'Offer Peace');
      $('#undo_button input').show().attr('disabled', !this.game.can_undo());

      $('#over_time_notice').hide();
      $('#reminder_sent_notice').hide();
      $('#over_time_options input').hide();
    } else if (this.game.players_include(this.user)) {
      $('#end_turn_button').hide();
      $('#surrender_button input').hide();
      $('#toggle_peace_button input').hide();
      $('#undo_button input').hide();

      if (this.game.can_skip()) {
        $('#player_options').show();
        $('#over_time_notice').show().text(this.game.current_user().username + ' is over time.');
        $('#over_time_options').show();

        if (this.game.can_send_reminder()) {
          $('#send_reminder_button').show();
          $('#send_reminder_button input').val('Send Reminder').attr('disabled', false);
        } else {
          $('#send_reminder_button').show();
          $('#send_reminder_button input').val('Reminder Sent').attr('disabled', true);
        }

        $('#skip_button input').show().attr('disabled', false)
          .text('Skip ' + this.game.current_user().username);

        $('#force_surrender_button input').show().attr('disabled', true);

        if (this.game.player_skip_count(this.game.current_user()) >= 2)
          $('#force_surrender_button input').attr('disabled', false);

      } else {
        $('#player_options').hide();
      }
    } else {
      $('#player_options').hide();
    }

    $('#turn_time').countdown({since: this.game.turn_started_at, compact: true, format: 'dhMS'});
    $('#turn_time').attr('class', (this.game.over_time() ? 'overtime' : ''));

    $('#spinner').hide();
  },

  disable_all: function() {
    $('#end_turn_button input').attr('disabled', true);
    $('#player_options input').attr('disabled', true);
  },

  show_win_dialog: function() {
    var dialog = new ConfirmationDialog('You won!', 'Congratulations! Would you like to share your win on Facebook?', 'Share', this, 'fb_share_win');
    dialog.open();
  },

  fb_share_win: function() {
    var img = this.game.preview_img || document.location.protocol + '//' + document.location.host + '/images/game/map_preview_placeholder.jpg';

    FB.ui({
      method: 'feed',
      display: 'popup',
      name: 'Elite Command: ' + this.game.name,
      link: document.location.href,
      picture: img,
      caption: this.user.username + ' won!',
      description: 'Elite Command is a free multiplayer turn-based strategy game. Play it now in your browser!',
      message: 'I just won a ' + this.game.starting_player_count + '-player game of Elite Command!'
    });
  },

  show_new_dialog: function() {
    var dialog = new ConfirmationDialog('Share your game?', 'Would you like to share this game to Facebook?', 'Share', this, 'fb_share_new');
    dialog.open();
  },

  fb_share_new: function() {
    var img = this.game.preview_img || document.location.protocol + '//' + document.location.host + '/images/game/map_preview_placeholder.jpg';

    FB.ui({
      method: 'feed',
      display: 'popup',
      name: 'Elite Command: ' + this.game.name,
      link: document.location.href,
      picture: img,
      caption: this.user.username + ' started a new game.',
      description: 'Elite Command is a free multiplayer turn-based strategy game. Play it now in your browser!',
      message: 'I just started a ' + this.game.starting_player_count + '-player game of Elite Command! Join me?'
    });
  }
});
