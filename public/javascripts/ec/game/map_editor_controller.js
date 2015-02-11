var MapEditorController = new JS.Class({
  include: JS.State,

  initialize: function(game_json, id, name, description, starting_credits) {
    var me = this;

    this.game = new Game('map', game_json);

    this.terrain = 0;
    this.brush_size = 1;
    this.player = 0;
    this.base = 'Base';
    this.unit = 'Infantry';
    this.terrain_modifier = 'road';
    this.pendown = false;

    $('#player_select select').change(function() {
      me.select_player(parseInt($(this).val()));
    });

    this.set_state('TerrainMode');
    this.update_interface();

    var t = $('#map').offset().top - $('#map').offsetParent().offset().top + 5;
    var l = $('#map').offset().left - $('#map').offsetParent().offset().left + 5;

    $('#map_event_catcher').css('top', t + 'px');
    $('#map_event_catcher').css('left', l + 'px');
    $('#map_event_catcher').css('cursor', 'crosshair');
    $('#scroll_message').hide();

    this.map_id = id;
    this.map_name = name;
    this.map_description = description;
    this.map_starting_credits = starting_credits;

    this.map = this.game.map;
    this.map.set_event_handler(this);
    this.map.disable_drag_scroll = true;
  },

  set_state: function(state) {
    this.state = state;
    this.setState(state);
  },

  select_terrain_type: function(type) {
    this.terrain = type;
    this.set_state('TerrainMode');
    this.update_interface();
  },

  select_terrain_brush_size: function(size) {
    this.brush_size = size;
    this.set_state('TerrainMode');
    this.update_interface();
  },

  select_base_type: function(type) {
    this.base = type;
    this.set_state('BaseMode');
    this.update_interface();
  },

  select_unit_type: function(type) {
    if (this.player != 0) {
      this.unit = type;
      this.set_state('UnitMode');
      this.update_interface();
    }
  },

  select_terrain_modifier: function(type) {
    this.terrain_modifier = type;
    this.set_state('TerrainModifierMode');
    this.update_interface();
  },

  select_delete: function() {
    this.set_state('DeleteMode');
    this.update_interface();
  },

  select_player: function(player) {
    this.player = player;
    if (this.state == 'UnitMode' && this.player == 0) this.set_state('BaseMode');
    this.update_interface();
  },

  states: {
    TerrainMode: {
      update_interface: function() {
        $('.editor_button').removeClass('selected');
        $('#terrain_' + this.terrain + '_button').addClass('selected');
        $('#terrain_brush_size_' + this.brush_size + '_button').addClass('selected');

        this.update_bases_and_units();
      },

      tile_mousedown: function(x, y) {
        this.pendown = true;

        if (this.brush_size == 1) {
          this.draw_terrain_at(x, y);
        } else {
          var rw = new GenericRangeWalker(x, y, this.brush_size - 1);

          var range_cost_map = new JS.Hash(null);

          for (var x = 0; x < this.map.tiles_width; x++) {
            for (var y = 0; y < this.map.tiles_height; y++) {
              var coord = new HCoordinate(x, y);
              range_cost_map.put(coord, 1);
            }
          }

          var rf = new RangeFinder(range_cost_map, rw);

          rf.possible_destination_tiles().forEach(function(pair) {
            var coord = pair.key;
            this.draw_terrain_at(coord.x, coord.y);
          }, this);
        }
      },

      tile_mousemove: function(x, y) {
        if (this.pendown) {
          this.tile_mousedown(x, y);
        }
      },

      tile_mouseup: function(x, y) {
        this.pendown = false;
      }
    },

    BaseMode: {
      update_interface: function() {
        $('.editor_button').removeClass('selected');
        $('#base_type_' + this.base + '_button').addClass('selected');

        this.update_bases_and_units();
      },

      tile_click: function(x, y) {
        var b = this.game.base_at(x, y);
        if (b) this.remove_base(b);

        var tm = this.game.terrain_modifier_at(x, y);
        if (tm) this.game.remove_terrain_modifier(tm);

        this.draw_terrain_at(x, y, $.inArray(this.base.toLowerCase(), GameConfig.tiles));

        b = new Base({ base_type: this.base, player: this.player, 'x': x, 'y': y });
        this.game.bases.add(b);
        b.add_to_map(this.map);

        this.game.update_modifiers_at(x, y);
      }
    },

    UnitMode: {
      update_interface: function() {
        $('.editor_button').removeClass('selected');
        $('#unit_type_' + this.unit + '_button').addClass('selected');

        this.update_bases_and_units();
      },

      tile_click: function(x, y) {
        var u = this.game.unit_at(x, y);
        if (u) this.remove_unit(u);

        u = new Unit({ unit_type: this.unit, player: this.player, 'x': x, 'y': y });

        if (u.tile_index_cost(this.map.tiles[y][x]) < 99) {
          this.game.units.add(u);
          u.add_to_map(this.map);
        }
      }
    },

    TerrainModifierMode: {
      update_interface: function() {
        $('.editor_button').removeClass('selected');
        $('#' + this.terrain_modifier + '_button').addClass('selected');

        this.update_bases_and_units();
      },

      tile_mousedown: function(x, y) {
        if (this.terrain_modifier == 'bridge') {
          if (!this.game.can_build_bridge_at(x, y)) return;
        }

        var tm = this.game.terrain_modifier_at(x, y);
        if (tm) this.game.remove_terrain_modifier(tm);

        var t = this.game.terrain_at(x, y);

        if ($.inArray(t, GameConfig.terrain_modifiers[this.terrain_modifier].allowed_on) > -1) {
          tm = new TerrainModifier({ terrain_name: this.terrain_modifier, 'x': x, 'y': y });
          this.game.add_terrain_modifier(tm);
        }

        this.pendown = true;
      },

      tile_mousemove: function(x, y) {
        if (this.pendown) {
          this.tile_mousedown(x, y);
        }
      },

      tile_mouseup: function(x, y) {
        this.pendown = false;
      }
    },

    DeleteMode: {
      update_interface: function() {
        $('.editor_button').removeClass('selected');
        $('#delete_button').addClass('selected');

        this.update_bases_and_units();
      },

      tile_mousedown: function(x, y) {
        this.pendown = true;

        var b = this.game.base_at(x, y);
        var u = this.game.unit_at(x, y);
        var tm = this.game.terrain_modifier_at(x, y);

        if (b) this.remove_base(b);
        if (u) this.remove_unit(u);
        if (tm) this.game.remove_terrain_modifier(tm);

        this.game.update_modifiers_at(x, y);
      },

      tile_mousemove: function(x, y) {
        if (this.pendown) this.tile_mousedown(x, y);
      },

      tile_mouseup: function(x, y) {
        this.pendown = false;
      }
    }
  },

  draw_terrain_at: function(x, y, t) {
    var terrain = t;
    if (!terrain) terrain = this.terrain;

    if (this.map.tiles[y] && this.map.tiles[y][x] != undefined) {
      var u = this.game.unit_at(x, y);

      if (!u || u.tile_index_cost(terrain) < 99) {
        this.map.tiles[y][x] = terrain;
        this.map.redraw_tile(x, y);

        var tm = this.game.terrain_modifier_at(x, y);
        if (tm) this.game.remove_terrain_modifier(tm);
      }
    }
  },

  remove_base: function(b) {
    this.draw_terrain_at(b.x, b.y, 0);
    this.game.bases.remove(b);
    b.remove();
  },

  remove_unit: function(u) {
    this.game.units.remove(u);
    u.remove();
  },

  update_bases_and_units: function() {
    var me = this;

    $('#bases .editor_button:not(.bridge):not(.road)').each(function(i, e) {
      e = $(e);
      var cb = e.css('background-position');
      if (typeof(cb) == 'undefined') cb = e.css('background-position-x') + ' ' + e.css('background-position-y');
      cb = cb.replace(/[a-z]/g, '').split(' ');
      var bx = parseInt(cb[0]);
      var by = parseInt(cb[1]);

      var new_pos = bx + 'px ' + (-34 * me.player) + 'px';

      e.css('background-position', new_pos);
    });

    if (this.player == 0) {
      $('#units .editor_button').addClass('disabled');
    } else {
      $('#units .editor_button').removeClass('disabled');

      $('#units .editor_button').each(function(i, e) {
        e = $(e);
        var cb = e.css('background-position');
        if (typeof(cb) == 'undefined') cb = e.css('background-position-x') + ' ' + e.css('background-position-y');
        cb = cb.replace(/[a-z]/g, '').split(' ');
        var bx = parseInt(cb[0]);
        var by = parseInt(cb[1]);

        var new_pos = bx + 'px ' + (-34 * me.player) + 'px';

        e.css('background-position', new_pos);
      });
    }
  },

  save: function(publish) {
    var bases = [];
    var units = [];
    var terrain_modifiers = [];

    for (var i in this.game.bases._0) {
      var b = this.game.bases._0[i];
      bases.push({ player: b.player, base_type: b.base_type, x: b.x, y: b.y, capturing: false });
    }

    for (var i in this.game.units._0) {
      var u = this.game.units._0[i];
      units.push({ player: u.player, unit_type: u.unit_type, x: u.x, y: u.y });
    }

    for (var i in this.game.terrain_modifiers) {
      var tm = this.game.terrain_modifiers[i];
      terrain_modifiers.push({ x: tm.x, y: tm.y, terrain_name: tm.terrain_name });
    }

    var params = {
      tiles: JSON.stringify(this.map.tiles),
      bases: JSON.stringify(bases),
      units: JSON.stringify(units),
      terrain_modifiers: JSON.stringify(terrain_modifiers)
    };

    if (publish) params.status = 'published';

    params = { map: params, _method: 'put' };

    $('#save_buttons input').attr('disabled', true);
    $.post('/maps/' + this.map_id + '.json', params, function(data) {
      if (!publish) {
        $('#save_buttons input').attr('disabled', false);
      } else {
        window.location.pathname = '/maps';
      }
    });
  },

  publish: function() {
    var dialog = new ConfirmationDialog('Publish your map?', "Once published, you will not be able to edit your map; instead, you will have the option to clone it and edit the copy.", "Publish", this, "confirm_publish");
    dialog.open();
  },

  confirm_publish: function() {
    this.save(true);
  },

  show_edit_dialog: function() {
    var dialog = new EditMapDetailsDialog(this);
    dialog.open();
  }
});

var EditMapDetailsDialog = new JS.Class(Dialog, {
  initialize: function(controller) {
    this.callSuper();

    var me = this;
    this.controller = controller;

    this.content.append('<h3>Edit Map Data</h3>');

    var table = $('<form><table></table></form>');

    var name_field = $('<input id="map_name"/>');
    name_field.val(this.controller.map_name);
    table.append($('<tr></tr>').append('<th><label>Name:</label></th>').append($('<td></td>').append(name_field)));

    var desc_field = $('<textarea id="map_description" rows="3" cols="25"></textarea>');
    desc_field.val(this.controller.map_description);
    table.append($('<tr></tr>').append('<th><label>Description:</label></th>').append($('<td></td>').append(desc_field)));

    var sc_field = $('<input id="map_starting_credits"/>');
    sc_field.val(this.controller.map_starting_credits);
    table.append($('<tr></tr>').append('<th><label>Starting Credits:</label></th>').append($('<td style="width: 200px"></td>').append(sc_field).append('<p>Note: Players will each start their first turn with the starting credits you specify <em>plus</em> the credits they earn from their starting bases.</p>')));

    this.content.append(table);

    var buttons = $('<p id="edit_details_buttons"></p>');
    buttons.css('text-align', 'right');

    var save_button = $('<button>Save</button>');
    save_button.addClass('main');
    save_button.click(function() {
      me.save();
    });

    var cancel_button = $('<button>Cancel</button>')
    cancel_button.click(function() {
      me.cancel();
    });

    buttons.append(save_button);
    buttons.append(cancel_button);

    this.content.append(buttons);
  },

  cancel: function() {
    this.close();
  },

  save: function() {
    var me = this;

    $('#edit_details_buttons button').attr('disabled', true);

    var params = {
      map: {
        name: $('#map_name').val(),
        description: $('#map_description').val(),
        starting_credits: $('#map_starting_credits').val()
      },
      _method: 'put'
    };

    $.post('/maps/' + this.controller.map_id + '.json', params, function(data) {
      if (data.success) {
        $('h2 b').text(params.map.name);
        $('h2 span i').text(params.map.starting_credits);
        me.controller.map_name = params.map.name;
        me.controller.map_description = params.map.description;
        me.controller.map_starting_credits = params.map.starting_credits;
        me.close();
      } else {
        var errors = $('<ul class="errors"></ul>');
        for (var i in data.errors) {
          errors.append('<li>' + data.errors[i] + '</li>');
        }

        me.content.children('h3').after(errors);
      }

      $('#edit_details_buttons button').attr('disabled', false);
    });
  }
});

var GenericRangeWalker = new JS.Class({
  initialize: function(x, y, max) {
    this.x = x;
    this.y = y;
    this.max = max;
  },

  get_x: function() { return this.x; },
  get_y: function() { return this.y; },
  get_min_range: function() { return 0; },
  get_max_range: function() { return this.max; },
  max_movement_points: function() { return this.get_max_range(); }
});
