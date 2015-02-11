var RangeWalkable = new JS.Interface([
  'get_x', 'get_y', 'get_min_range', 'get_max_range'
]);

var RangeFinder = new JS.Class(PathFinder, {
  initialize: function(cost_map, walker) {
    JS.Interface.ensure(walker, RangeWalkable);

    this.cost_map = cost_map;
    this.walker = walker;
    this.min = walker.get_min_range();
    this.max = walker.get_max_range();

    var starting_coord = new HCoordinate(this.walker.get_x(), this.walker.get_y());

    this.found_tiles = new JS.Hash(null);
    this.found_tiles.put(starting_coord, this.max);

    this.initialize_zoc_tiles();
  },

  initialize_zoc_tiles: function() {
    this.zoc_tiles = new JS.Set([]);
  },

  possible_destination_tiles: function() {
    return this.callSuper().removeIf(function(pair) {
      return this.max - pair.value < this.min;
    }, this);
  }
});
