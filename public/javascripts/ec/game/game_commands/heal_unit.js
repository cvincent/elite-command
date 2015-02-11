var HealUnit = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
    this.x = params.x;
    this.y = params.y;
  },

  class_name: function() {
    return 'HealUnit';
  },

  execute: function() {
    var unit = this.game.unit_at(this.x, this.y);

    this.modify(unit, 'health', unit.health + Math.ceil((10 - unit.health) / 2))
    this.modify(unit, 'movement_points', 0);
    this.modify(unit, 'attacks', unit.def.attack_phases);
    this.modify(unit, 'healed', true);
  },

  can_undo: function() {
    return true;
  }
});
