var AttackDialog = new JS.Class(Dialog, {
  initialize: function(attacker, defender, game, map, event_handler, confirm_method, cancel_method) {
    this.callSuper();
    this.content.append('<h3>' + attacker.def.human_name + ' vs ' + defender.def.human_name + '</j3>');

    var attacker_terrain = game.terrain_at(attacker.x, attacker.y);
    var defender_terrain = game.terrain_at(defender.x, defender.y);

    var sprites = $('<div id="attack_dialog_sprites"></div>');

    var ab = game.base_at(attacker.x, attacker.y);
    var ab_sprite = $('');
    if (ab) {
      ab_sprite = new Base({ base_type: ab.base_type, player: ab.player }).base.e.clone();
    }

    var atm = game.terrain_modifier_at(attacker.x, attacker.y);
    var atm_sprite = $('');
    if (atm) {
      atm_sprite = new TerrainModifier({
        terrain_name: atm.terrain_name, x: atm.x, y: atm.y
      }).sprite.e.clone();
    }

    var a_sprite = new Unit({ unit_type: attacker.unit_type, player: attacker.player });
    a_sprite.face_right();
    a_sprite.movement_indicator.e.hide();
    a_sprite.attacks_indicator.e.hide();
    a_sprite.set_health(attacker.health);
    sprites.append(
      $('<div id="attack_dialog_a_sprite"></div>')
        .append(Map.element_for_tile_index(map.tile_index(attacker.x, attacker.y)).show())
          .append(ab_sprite)
            .append(atm_sprite)
              .append(a_sprite.unit.e)
                .append(a_sprite.health_indicator.e)
    );

    var db = game.base_at(defender.x, defender.y);
    var db_sprite = $('');
    if (db) {
      db_sprite = new Base({ base_type: db.base_type, player: db.player }).base.e.clone();
    }

    var dtm = game.terrain_modifier_at(defender.x, defender.y);
    var dtm_sprite = $('');
    if (dtm) {
      dtm_sprite = new TerrainModifier({
        terrain_name: dtm.terrain_name, x: dtm.x, y: dtm.y
      }).sprite.e.clone();
    }

    var d_sprite = new Unit({ unit_type: defender.unit_type, player: defender.player });
    d_sprite.face_left();
    a_sprite.movement_indicator.e.hide();
    a_sprite.attacks_indicator.e.hide();
    d_sprite.set_health(defender.health);
    sprites.append(
      $('<div id="attack_dialog_d_sprite"></div>')
        .append(Map.element_for_tile_index(map.tile_index(defender.x, defender.y)).show())
          .append(db_sprite)
            .append(dtm_sprite)
              .append(d_sprite.unit.e)
                .append(d_sprite.health_indicator.e)
    );

    this.content.append(sprites);

    var range_cost_map = new JS.Hash(null);

    for (var x = 0; x < map.tiles_width; x++) {
      for (var y = 0; y < map.tiles_height; y++) {
        var coord = new HCoordinate(x, y);
        range_cost_map.put(coord, 1);
      }
    }

    var rf = new RangeFinder(range_cost_map, defender);
    var poss_targets = rf.possible_destination_tiles();
    var no_counterattack_reason = 'range';
    var counterattack = poss_targets.any(function(pair) {
      return pair.key.equals(new HCoordinate(attacker.x, attacker.y));
    });

    if (counterattack) {
      counterattack = defender.can_attack_unit_type(attacker.unit_type);
      no_counterattack_reason = 'type';
    }

    var table = $('<table class="attack_dialog_table"></table>');
    table.append('<tr class="header_row"><th>&nbsp;</th><th>Us</th><th>Them</th></tr>');
    table.append(
      '<tr>' +
        '<th>Base (Attack/Armor):</th>' +
        '<td>' + attacker.base_combat_display(defender) + '</td>' +
        '<td>' + defender.base_combat_display(attacker) + '</td>' +
      '</tr>'
    );
    table.append(
      '<tr>' +
        '<th>Terrain Modifier:</th>' +
          '<td>' + attacker.terrain_bonuses_display(attacker_terrain) + '</td>' +
          '<td>' + defender.terrain_bonuses_display(defender_terrain) + '</td>' +
        '</th>' +
      '</tr>'
    );
    if (defender.flank_penalty > 0) {
      table.append(
        '<tr>' +
          '<th>Flank Penalty*:</th>' +
          '<td>N/A</td>' +
          '<td>' + defender.flank_penalty_display() + '</td>' +
        '</tr>'
      );
    }
    if (db && db.capture_phase != null) {
      table.append(
        '<tr>' +
          '<th>Capture Penalty:</th>' +
          '<td>N/A</td>' +
          '<td>' + defender.capture_penalty_display() + '</td>' +
        '</tr>'
      );
    }
    table.append(
      '<tr>' +
        '<th>Final:</th>' +
        '<td>' + attacker.total_combat_display(defender, attacker_terrain) + '</td>' +
        '<td>' + defender.total_combat_display(attacker, defender_terrain, (db && db.capture_phase != null)) + '</td>' +
      '</tr>'
    );
    table.append(
      '<tr>' +
        '<th>Hit Chance:</th>' +
        '<td>' + attacker.hit_chance_display(defender, attacker_terrain, defender_terrain, (db && db.capture_phase != null)) + '</td>' +
        '<td>' + defender.hit_chance_display(attacker, defender_terrain, attacker_terrain) + '</td>' +
      '</tr>'
    );
    this.content.append(table);

    if (defender.flank_penalty > 0) {
      this.content.append("<p>*Each successive attack on the same unit applies a flank penalty.</p>");
    }
    if (!counterattack) {
      if (no_counterattack_reason == 'range') {
        this.content.append("<p>&dagger;The defending unit will be unable to counterattack because the attacker is outside its range.</p>");
      } else {
        this.content.append("<p>&dagger;The defending unit will be unable to counterattack because it is unable to attack " + attacker.def.armor_type + " units.</p>");
      }
    } else {
      this.content.append("<p>&dagger;The defending unit will counterattack.</p>");
    }

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    var attack_button = $('<button class="main">Attack</button>').click(function() {
      event_handler[confirm_method]();
    });
    buttons.append(attack_button);

    var cancel_button = $('<button>Cancel</button>').click(function() {
      event_handler[cancel_method]();
    });
    buttons.append(cancel_button);

    this.content.append(buttons);
  },
});
