var BuyUnitDialog = new JS.Class(Dialog, {
  initialize: function(game, base, event_handler, confirm_method, cancel_method) {
    this.callSuper();

    this.event_handler = event_handler;
    this.confirm_method = confirm_method;
    this.cancel_method = cancel_method;
    this.game = game;

    this.content.append('<h3>Build a unit?<h3>');
    this.content.append('<p>Your unit will be built and the credits deducted immediately. The unit will be able to act on the next turn.</p>');

    var def = GameConfig.bases[base.base_type];
    var list = $('<ul></ul>');

    for (var i in def.can_build) {
      if (game.type == 'subscriber' || $.inArray(def.can_build[i], GameConfig.free_unit_types) > -1) {
        var unit_type = def.can_build[i];
        var buy_link = this.create_buy_link(unit_type);
        var stats_link = this.create_stats_link(unit_type);

        if (GameConfig.units[unit_type].credits > game.player_credits(game.player_by_id(base.player_id))) {
          buy_link.addClass('deactivated');
          buy_link.unbind('click');
          buy_link.click(function() { return false; });
        }

        var item = $('<li></li>');
        item.append(buy_link);
        item.append(' (' + GameConfig.units[unit_type].credits + ' credits)');
        item.append(' ['); item.append(stats_link); item.append(']');
        
        list.append(item);
      }
    }

    this.content.append(list);

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    var cancel_button = $('<button>Cancel</button>');
    cancel_button.click(function() {
      event_handler[cancel_method]();
    });

    buttons.append(cancel_button);
    this.content.append(buttons);
  },

  create_buy_link: function(unit_type) {
    var me = this;

    return $('<a href="#">' + GameConfig.units[unit_type].human_name + '</a>').click(function() {
      me.event_handler[me.confirm_method](unit_type);
      return false;
    });
  },

  create_stats_link: function(unit_type) {
    var me = this;

    return $('<a href="#">unit stats</a>').click(function() {
      me.show_unit_stats(unit_type);
      return false;
    });
  },

  show_unit_stats: function(unit_type) {
    this.unit_stats_dialog = new UnitStatsDialog(
      unit_type, this.game.current_user_idx(), this, 'close_unit_stats'
    );
    this.unit_stats_dialog.open();
  },

  close_unit_stats: function() {
    this.unit_stats_dialog.close();
    this.unit_stats_dialog = null;
  }
});
