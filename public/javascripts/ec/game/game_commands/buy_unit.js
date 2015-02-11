var BuyUnit = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();

    this.loc = new HCoordinate(params.x, params.y);
    this.unit_type = params.unit_type;
  },

  class_name: function() {
    return 'BuyUnit';
  },

  execute: function() {
    var b = this.game.base_at(this.loc.x, this.loc.y);

    this.create_unit(this.user, this.unit_type, b.x, b.y);

    var unit = this.game.unit_at(b.x, b.y);
    this.modify(unit, 'movement_points', 0);
    this.modify(unit, 'attacks', unit.def.attack_phases);

    var player_num = this.game.player_number(this.user);
    this.modify_credits(player_num, this.game._player_credits[player_num - 1] - unit.def.credits);
  },

  can_undo: function() {
    return true;
  }
});
