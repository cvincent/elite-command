var Attack = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();

    this.unit_loc = new HCoordinate(params.unit_x, params.unit_y);
    this.target_loc = new HCoordinate(params.target_x, params.target_y);

    this.attacker_damage = null;
    this.defender_damage = null;
  },

  class_name: function() {
    return 'Attack';
  },

  execute: function() {
    var attacker = this.game.unit_at(this.unit_loc.x, this.unit_loc.y);
    var defender = this.game.unit_at(this.target_loc.x, this.target_loc.y);

    attacker.face_unit(defender);
    defender.face_unit(attacker);

    if (attacker.def.attack_type == 'move_attack' || attacker.def.attack_type == 'exclusive') {
      this.modify(attacker, 'movement_points', 0);
    }

    this.modify(attacker, 'attacks', attacker.attacks + 1);
    this.modify(attacker, 'attacked', true);
    this.modify(defender, 'flank_penalty', defender.flank_penalty + 1);
  },

  post_commit: function(result) {
    this.attacker_damage = result.attacker_damage;
    this.defender_damage = result.defender_damage;
    this.callSuper();
  },

  finish: function() {
    var attacker = this.game.unit_at(this.unit_loc.x, this.unit_loc.y);
    var defender = this.game.unit_at(this.target_loc.x, this.target_loc.y);

    this.modify(attacker, 'health', attacker.health - this.defender_damage);
    this.modify(defender, 'health', defender.health - this.attacker_damage);

    if (attacker.health <= 0) {
      this.destroy_unit(attacker);
    }

    if (defender.health <= 0) {
      var capturing_base = this.game.base_at(defender.x, defender.y);
      if (capturing_base) this.cancel_capture(capturing_base);

      this.destroy_unit(defender);
    }
  },
});
