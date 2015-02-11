var GameAlertsMenu = new JS.Class({
  initialize: function(game_alerts, current_game_id) {
    this.e = $('#game_alerts');
    this.ul = this.e.children('ul');

    this.game_alerts = game_alerts;
    this.current_game_id = current_game_id;

    this.draw_menu();
  },

  add_alert: function(ga) {
    this.game_alerts.push(ga);
    this.draw_menu();
  },

  remove_alerts_for_game_id: function(gid) {
    var new_game_alerts = [];
    for (var i in this.game_alerts) {
      if (this.game_alerts[i].game_id != gid) {
        new_game_alerts.push(this.game_alerts[i]);
      }
    }

    this.game_alerts = new_game_alerts;
    this.draw_menu();
  },

  draw_menu: function() {
    var count = 0;

    this.sort_game_alerts();
    this.ul.empty();

    if (this.game_alerts.length > 0) {
      for (var i in this.game_alerts) {
        var ga = this.game_alerts[i];
        count++;

        if (ga.msg_class == 'player_turn') {
          this.ul.append('<li>' + this.link_to_game_id(ga.game_id, ga.game_name) + ' - Your turn!</li>');
        } else if (ga.msg_class == 'over_time') {
          this.ul.append('<li>' + this.link_to_game_id(ga.game_id, ga.game_name) + ' - Time limit exceeded!</li>');
        } else if (ga.msg_class == 'new_message') {
          this.ul.append('<li>' + this.link_to_message(ga.thread_identifier, ga.message_id, ga.sender_username) + '</li>');
        }
      }

      document.title = 'Elite Command (' + count + ')';
      this.e.show();
    }

    if (count == 0) {
      document.title = 'Elite Command';
      this.e.hide();
    }
  },

  sort_game_alerts: function() {
    this.game_alerts = new JS.Set(this.game_alerts).sortBy(function(ga) {
      if (ga.msg_class == 'new_message') return 0;
      if (ga.msg_class == 'player_turn') return 1;
      if (ga.msg_class == 'over_time')   return 2;
    });
  },

  link_to_game_id: function(gid, text) {
    return '<a href="/games/' + gid + '">' + text + '</a>';
  },

  link_to_message: function(thread_identifier, message_id, sender_username) {
    return '<a href="/messages/' + thread_identifier + '/thread#' + message_id + '">New private message from ' + sender_username + '!</a>';
  }
});
