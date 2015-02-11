var ForceSurrender = new JS.Class(EndTurn, {
  initialize: function(game, user, params) {
    this.callSuper(game, game.current_user(), { surrender: true, skipping: false })
  },

  class_name: function() {
    return 'ForceSurrender';
  },

  execute: function() {
    this.callSuper();
  }
});
