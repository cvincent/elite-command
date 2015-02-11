var UserCometController = new JS.Class({
  initialize: function() {
    this.achievement_queue = [];
    this.animating_achievement = false;
  },

  received_game_alert: function(data) {
    window.GameAlerts.add_alert(data.game_alert);
  },

  received_achievement: function(data) {
    if (console) console.log(data);

    this.achievement_queue.push(data);
    this._animate_next_achievement();
  },

  _animate_next_achievement: function() {
    var me = this;

    if (!this.animating_achievement && this.achievement_queue.length > 0) {
      this.animating_achievement = true;
      data = this.achievement_queue.shift();

      var a = $('#achievement');
      a.children('h3').text(data.name);
      a.children('p').text(data.description);
      a.children('img').attr('src', '/images/achievements/' + data.achievement + '_large.png');

      if (data.tier > 1) {
        a.children('h3').append(' (x' + data.tier + ')');
      }

      a.slideDown().delay(5000).fadeOut(400, function() {
        me.animating_achievement = false;
        me._animate_next_achievement();
      });
    }
  }
});
