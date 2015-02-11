var SkipPlayer = new JS.Class(EndTurn, {
  initialize: function(game, user, params) {
    params = params || {};
    params.skipped_by = user.id;
    params.skipping = true;
    this.callSuper(game, game.current_user(), params);
  },

  class_name: function() {
    return 'SkipPlayer';
  },

  execute: function() {
    this.modify_skip_count(this.user, this.game.player_skip_count(this.user) + 1);
    this.callSuper();
  }
});
