var MoveUnit = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper();

    this.unit_location = [this.params.unit_x, this.params.unit_y, this.params.unit_slot];
    this.dest_x = this.params.dest_x;
    this.dest_y = this.params.dest_y;
  },

  class_name: function() {
    return 'MoveUnit';
  },

  execute: function() {
    var unit = this.game.unit_at(this.unit_location[0], this.unit_location[1], this.unit_location[2]);

    var cost_map = new JS.Hash(null);

    for (var x = 0; x < this.game.map.tiles_width; x++) {
      for (var y = 0; y < this.game.map.tiles_height; y++) {
        var coords = new HCoordinate(x, y);
        var cost = unit.terrain_cost(this.game.terrain_at(x, y), this.game.unmodified_terrain_at(x, y));
        cost_map.put(coords, cost);
      }
    }

    var pf = new PathFinder(cost_map, unit, this.game.enemy_units(this.user));
    var remaining_mv = pf.possible_destination_tiles().get(new HCoordinate(this.dest_x, this.dest_y));

    this.move_unit(this.unit_location[0], this.unit_location[1], this.unit_location[2], this.dest_x, this.dest_y, null);
    this.modify(unit, 'movement_points', remaining_mv);
    this.modify(unit, 'moved', true);

    if (unit.def.attack_type == 'exclusive') {
      this.modify(unit, 'attacks', unit.def.attack_phases);
    }
  },

  can_undo: function() {
    return true;
  }
});
