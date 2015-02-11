var TmRoadSprite = new JS.Class(Sprite, {
  initialize: function() {
    this.callSuper(SpriteSheets.roads);
  },

  update_for_surrounding_terrain: function(surrounding) {
    var connections = '';

    for (var i in surrounding) {
      var tname = surrounding[i];
      if (
        tname == 'road' || tname == 'base' ||
        tname == 'airfield' || tname == 'seaport' ||
        tname == 'bridge'
        ) {
        connections = connections + '1';
      } else {
        connections = connections + '0';
      }
    }

    this.set_sprite('road', connections);
  }
});
