var CaptureBase = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
    this.x = params.x;
    this.y = params.y;
  },

  class_name: function() {
    return 'CaptureBase';
  },

  execute: function() {
    var base = this.game.base_at(this.x, this.y);
    this.start_capture(base, this.user);
  },

  can_undo: function() {
    return true;
  }
});
