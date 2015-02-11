var FieldHealUnit = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
    this.x = params.x;
    this.y = params.y;
    this.tx = params.tx;
    this.ty = params.ty;
  },

  class_name: function() {
    return 'FieldHealUnit';
  },

  execute: function() {
    var unit = this.game.unit_at(this.x, this.y);
    var target = this.game.unit_at(this.tx, this.ty);

    this.modify(target, 'health', target.health + Math.ceil((10 - target.health) / 3))
    this.modify(unit, 'movement_points', 0);
    this.modify(unit, 'attacks', unit.def.attack_phases);
  },

  can_undo: function() {
    return true;
  }
});
