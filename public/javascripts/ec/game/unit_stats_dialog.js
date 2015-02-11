var UnitStatsDialog = new JS.Class(Dialog, {
  initialize: function(unit_type, player, event_handler, close_method) {
    var me = this;
    this.callSuper();

    var def = GameConfig.units[unit_type];

    this.content.append('<h3>' + def.human_name + '</h3>');

    var sprite = new Unit({ 'unit_type': unit_type, 'player': player });
    sprite.health_indicator.e.hide();
    sprite.movement_indicator.e.hide();
    sprite.attacks_indicator.e.hide();
    this.content.append($('<div id="unit_stats_sprite"></div>').css('margin-right', '10px').append(sprite.unit.e));

    var tabs = $('<div class="dialog_tabs"></div>');

    var general_tab = $('<a href="#">General</a>');
    general_tab.click(function() { me.set_tab(this, 'general'); return false; });
    tabs.append(general_tab);

    var movement_tab = $('<a href="#">Movement</a>');
    movement_tab.click(function() { me.set_tab(this, 'movement'); return false; });
    tabs.append(movement_tab);

    this.content.append(tabs);



    // GENERAL TAB

    var general_tab_content = $('<div id="general_tab_content" class="tab_content" style="display: none"></div>');
    var list = $('<ul id="unit_stats_list"></ul>');

    list.append('<li>Credits: ' + def.credits + '</li>');
    list.append('<li>Armor: ' + def.armor + '</li>');

    var armor_type = def.armor_type.charAt(0).toUpperCase() + def.armor_type.slice(1);
    list.append('<li>Armor Type: ' + armor_type + '</li>');

    var attack_list_item = $('<li>Attack: </li>');
    var attack_list = $('<ul></ul>');

    for (var i in def.attack) {
      var armor_type = i.charAt(0).toUpperCase() + i.slice(1);

      if (def.attack[i] != null && def.attack[i] != 0) {
        attack_list.append('<li>' + armor_type + ': ' + def.attack[i]);
      } else {
        attack_list.append('<li>' + armor_type + ': N/A</li>');
      }
    }

    attack_list_item.append(attack_list);
    list.append(attack_list_item);

    if (def.range[0] != def.range[1]) {
      list.append('<li>Range: ' + def.range[0] + '-' + def.range[1] + '</li>');
    } else {
      list.append('<li>Range: ' + def.range[0] + '</li>');
    }

    var add_terrain_bonuses = false;
    var terrain_bonuses_list_item = $('<li>Terrain Bonuses: </li>');
    var terrain_bonuses_list = $('<ul></ul>');

    for (var i in def.attack_bonus) {
      var terrain = i.charAt(0).toUpperCase() + i.slice(1);
      terrain = terrain.replace('_', ' ');

      var a = def.attack_bonus[i];
      if (a != null && a > 0) a = '+' + a;

      var d = def.armor_bonus[i];
      if (d != null && d > 0) d = '+' + d;

      if ((a != 0 && a != null) || (d != 0 && d != null)) {
        add_terrain_bonuses = true;
        terrain_bonuses_list.append('<li>' + terrain + ': ' + a + '/' + d + '</li>');
      }
    }

    if (add_terrain_bonuses) {
      terrain_bonuses_list_item.append(terrain_bonuses_list);
      list.append(terrain_bonuses_list_item);
    }

    if (def.armor_type != 'naval' && def.movement.mountains == 99) {
      list.append('<li>Cannot pass through mountains</li>');
    }

    if (def.attack_phases > 1) {
      list.append('<li>Can attack ' + def.attack_phases + ' times per turn</li>');
    }

    if (def.attack_type == 'free') {
      list.append('<li>Can move after attacking</li>');
    } else if (def.attack_type == 'exclusive') {
      list.append('<li>Can only move OR attack in a turn</li>');
    }

    var zoc_array = [];

    if (typeof def.zoc == 'object') {
      for (var i in def.zoc) {
        zoc_array.push(def.zoc[i]);
      }
    } else if (def.zoc == 'normal') {
      for (var i in def.attack) {
        if (def.attack[i]) {
          zoc_array.push(i);
        }
      }
    }

    var zoc = '';
    for (var i in zoc_array) {
      if (zoc != '') {
        if (zoc_array.length > 2) {
          zoc = zoc + ', ';
        } else {
          zoc = zoc + ' ';
        }

        if (i == zoc_array.length - 1) {
          zoc = zoc + 'and ';
        }
      }

      zoc = zoc + zoc_array[i];
    }

    if (zoc == '') {
      list.append('<li>Does not assert Zone of Control</li>');
    } else {
      list.append('<li>Asserts Zone of Control against ' + zoc + ' units</li>');
    }

    if (def.can_capture) {
      list.append('<li>Can capture bases</li>');
    }

    if (def.armor_type == 'air') {
      list.append('<li>Will be shot down if turn is ended while over an enemy base</li>');
    }

    if (def.notes && def.notes.length > 0) {
      for (var i in def.notes) {
        list.append('<li>' + def.notes[i] + '</li>');
      }
    }

    if (def.can_heal) {
      var healing = 'Can heal ';
      for (var i in def.can_heal) {
        if (i > 0) healing += ', ';
        if (i > 0 && i == def.can_heal.length - 1) healing += 'and ';
        healing += def.can_heal[i];
      }
      healing += ' units';
      list.append('<li>' + healing + '</li>');
    }

    general_tab_content.append(list);
    this.content.append(general_tab_content);



    // MOVEMENT TAB
    
    var movement_tab_content = $('<div id="movement_tab_content" class="tab_content" style="display: none"></div>');

    var mlist = $("<ul></ul>");
    var movement_list_item = $('<li>Movement Costs: </li>');
    var movement_list = $('<ul></ul>');

    for (var i in GameConfig.tiles) {
      var terrain = GameConfig.tiles[i];
      var terrain_name = terrain.replace('_', ' ');
      terrain_name = terrain_name.charAt(0).toUpperCase() + terrain_name.slice(1);

      if (def.movement[terrain] && def.movement[terrain] < 99) {
        movement_list.append('<li>' + terrain_name + ': ' + def.movement[terrain] + '</li>');
      }
    }

    mlist.append('<li>Movement Points: ' + def.movement_points + '</li>');
    movement_list_item.append(movement_list);
    mlist.append(movement_list_item);
    movement_tab_content.append(mlist);

    this.content.append(movement_tab_content);



    // BUTTONS

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    var close_button = $('<button>Close</button>');
    close_button.click(function() {
      event_handler[close_method]();
    });

    buttons.append(close_button);
    this.content.append(buttons);

    this.set_tab(general_tab, 'general');
  },

  set_tab: function(tab_link, tab_name) {
    $('.current_tab').removeClass('current_tab');
    $(tab_link).addClass('current_tab');
    $('.current_tab_content').hide();
    $('#' + tab_name + '_tab_content').addClass('current_tab_content').show();
  }
});
