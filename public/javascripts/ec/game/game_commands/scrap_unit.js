var ScrapUnit = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();
    this.x = params.x;
    this.y = params.y;
  },

  class_name: function() {
    return 'ScrapUnit';
  },

  execute: function() {
    var unit = this.game.unit_at(this.x, this.y);
    var pn = this.game.player_number(this.user);

    this.destroy_unit(unit);
    this.modify_credits(pn, this.game._player_credits[pn - 1] + unit.scrap_value());
  },

  can_undo: function() {
    return true;
  }
});
