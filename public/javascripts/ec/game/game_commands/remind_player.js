var RemindPlayer = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
  },

  class_name: function() {
    return 'RemindPlayer';
  },

  execute: function() {
    this.modify_game('reminder_sent_at', new Date());
  }
})
