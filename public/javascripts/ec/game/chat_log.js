var ChatLog = new JS.Class({
  initialize: function(log_id, log_ev_catcher_id, input_id, game) {
    var me = this;

    this.log = $('#' + log_id);
    this.log_event_catcher = $('#' + log_ev_catcher_id);
    this.input = $('#' + input_id);
    this.game = game;

    this.input.keypress(function(e) {
      if (e.keyCode == 13) {
        msg = me.input.val();
        me.input.val('');
        me.send_message(msg);
        return false;
      }
    });

    this.log_event_catcher.mousewheel(function(e, d) {
      $.browser.safari = ( $.browser.safari && /chrome/.test(navigator.userAgent.toLowerCase()) ) ? false : true;

      var scroll = d;
      if (($.browser.webkit && !$.browser.safari) || $.browser.mozilla) {
        scroll *= 100;
      }

      me.log.attr('scrollTop', me.log.attr('scrollTop') + (scroll * -1));
      e.preventDefault();
    });

    for (var i in this.game.chat_log) {
      var msg = this.game.chat_log[i];

      if (msg.msg_class == 'chat_message') {
        this.received_chat_message(msg);
      } else {
        this.received_info_message(msg);
      }
    }
  },

  send_message: function(msg) {
    $.post('/games/' + this.game.id + '/chat', { message: msg });
  },

  received_chat_message: function(msg) {
    var user = this.game.player_by_id(msg.user_id);
    var user_idx = this.game.player_number(user);

    var div = $('<div></div>');
    div.addClass('chat_message');
    div.addClass('player_' + user_idx).text(user.username + ': ' + msg.message);

    this.log.append(div);
    this.log.attr('scrollTop', 10000000)
  },

  received_info_message: function(msg) {
    var div = $('<div></div>');
    div.addClass('info_message');
    div.html(msg.message);

    if (msg.user_id) {
      var user = this.game.player_by_id(msg.user_id);
      var user_idx = (user != null ? this.game.player_number(user) : this.game.players.length);
      div.addClass('player_' + user_idx);
    }

    this.log.append(div);
    this.log.attr('scrollTop', 10000000)
  }
});
