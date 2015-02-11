var Walkable = new JS.Interface([
  'max_movement_points', 'get_movement_points', 'tile_index_cost', 'get_x', 'get_y', 'can_zoc'
]);

var PathFinder = new JS.Class({
  initialize: function(cost_map, walker, zoc_walkers) {
    JS.Interface.ensure(walker, Walkable);

    zoc_walkers.forEach(function(zoc_walker) {
      JS.Interface.ensure(zoc_walker, Walkable);
    });

    this.cost_map = cost_map;
    this.walker = walker;
    this.zoc_walkers = zoc_walkers;

    var starting_coord = new HCoordinate(this.walker.get_x(), this.walker.get_y());

    this.found_tiles = new JS.Hash(null);
    this.found_tiles.put(starting_coord, this.walker.get_movement_points());

    this.initialize_zoc_tiles();
  },

  initialize_zoc_tiles: function() {
    this.zoc_tiles = new JS.Set([]);

    this.zoc_walkers.forEach(function(zoc_walker) {
      if (zoc_walker.can_zoc(this.walker)) {
        var coord = new HCoordinate(zoc_walker.x, zoc_walker.y);
        this.zoc_tiles.add(coord);

        this.each_tile_from(coord, function(zcoord) {
          this.zoc_tiles.add(zcoord);
        });
      }
    }, this);
  },

  possible_destination_tiles: function() {
    var starting_points = new JS.Set([new HCoordinate(this.walker.x, this.walker.y)]);

    while (true) {
      var newly_found = new JS.Set([]);

      starting_points.forEach(function(tile) {
        var moves = this.possible_moves_from(tile, this.found_tiles.get(tile));

        moves.forEachPair(function(new_tile, rm_pts) {
          var old_rm_pts = this.found_tiles.get(new_tile);

          if (!old_rm_pts || old_rm_pts < rm_pts) {
            newly_found.add(new_tile);
            this.found_tiles.put(new_tile, rm_pts);
          }
        }, this);
      }, this);

      if (newly_found.length == 0) break;
      starting_points = newly_found;
    }

    if (this.zoc_walkers) {
      this.zoc_walkers.forEach(function(zoc_walker) {
        this.found_tiles.remove(new HCoordinate(zoc_walker.x, zoc_walker.y));
      }, this);
    }

    return this.found_tiles;
  },

  possible_moves_from: function(coord, points) {
    var ret = new JS.Hash(null);

    this.each_tile_from(coord, function(new_coord) {
      var cost = this.cost_map.get(new_coord);

      if (cost && cost <= this.walker.max_movement_points()) {
        if (this.zoc_tiles.contains(coord) && this.zoc_tiles.contains(new_coord)) {
          // Moving from one ZoC tile to another costs the walker's maximum movement points
          cost = this.walker.max_movement_points();
        }
      } else {
        cost = 99;
      }

      if (points - cost >= 0) ret.put(new_coord, points - cost);
    });



    return ret;
  },

  each_tile_from: function(coord, op) {
    var tiles = PathFinder.surrounding_tiles(coord);

    for (var i in tiles) {
      this.each_tile_from_op = op;
      this.each_tile_from_op(tiles[i]);
    }
  },

  extend: {
    surrounding_tiles: function(coord) {
      ret = [];

      for (var i = 1; i <= 6; i++) {
        var new_x = 0;
        var new_y = 0;

        switch (i) {
        case 1:
          new_x = coord.x - 1;
          new_y = coord.y;
          break;
        case 2:
          new_x = coord.x - (coord.y % 2 == 0 ? 1 : 0);
          new_y = coord.y + 1;
          break;
        case 3:
          new_x = coord.x + (coord.y % 2 == 0 ? 0 : 1);
          new_y = coord.y + 1;
          break;
        case 4:
          new_x = coord.x + 1;
          new_y = coord.y;
          break;
        case 5:
          new_x = coord.x + (coord.y % 2 == 0 ? 0 : 1);
          new_y = coord.y - 1;
          break;
        case 6:
          new_x = coord.x - (coord.y % 2 == 0 ? 1 : 0);
          new_y = coord.y - 1;
          break;
        }

        ret.push(new HCoordinate(new_x, new_y));
      }

      return ret;
    }
  }
});
