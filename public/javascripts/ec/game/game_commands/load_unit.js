var LoadUnit = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();

    this.x = this.params.x;
    this.y = this.params.y;
    this.tx = this.params.tx;
    this.ty = this.params.ty;
  },

  class_name: function() {
    return 'LoadUnit';
  },

  execute: function() {
    var transport = this.game.unit_at(this.tx, this.ty);
    this.move_unit(this.x, this.y, null, this.tx, this.ty, transport.loaded_units.length);
  },

  can_undo: function() {
    return true;
  }
});
