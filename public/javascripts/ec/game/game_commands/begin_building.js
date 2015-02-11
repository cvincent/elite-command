var BeginBuilding = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
    this.x = params.x; this.y = params.y;
    this.building = params.building;
  },

  class_name: function() {
    return 'BeginBuilding';
  },

  execute: function() {
    var unit = this.game.unit_at(this.x, this.y);

    this.modify(unit, 'current_build', this.building);
    this.modify(unit, 'build_phase', -1 + unit.def.can_build[this.building].turns);
    this.modify(unit, 'attacks', unit.def.attack_phases);
    this.modify(unit, 'movement_points', 0);

    var player_num = this.game.player_number(this.user);
    this.modify_credits(player_num, this.game._player_credits[player_num - 1] - unit.def.can_build[this.building].credits);
  },

  can_undo: function() {
    return true;
  }
});
