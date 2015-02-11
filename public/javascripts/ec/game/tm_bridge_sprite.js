var TmBridgeSprite = new JS.Class(Sprite, {
  initialize: function() {
    this.callSuper(SpriteSheets.bridges);
  },

  update_for_surrounding_terrain: function(surrounding) {
    var connections = TmBridgeSprite.bridge_type_within(surrounding);
    this.set_sprite('bridge', connections);
  },

  extend: {
    bridge_type_within: function(surrounding) {
      var connections = '';

      for (var i in surrounding) {
        var tname = surrounding[i];
        if (TmBridgeSprite.can_connect_to_terrain_type(tname)) {
          connections = '1' + connections;
        } else {
          connections = '0' + connections;
        }
      }

      connections = parseInt(connections, 2);

      var prioritized_bridges = ['110110', '011011', '101101', '010010', '001001', '100100'];
      var ret = null;

      for (var i in prioritized_bridges) {
        var bridge = parseInt(prioritized_bridges[i], 2);

        if ((connections & bridge) == bridge) {
          ret = prioritized_bridges[i];
          break;
        }
      }

      return ret;
    },

    can_connect_to_terrain_type: function(tname) {
      return tname != 'sea' && tname != 'ford' &&
      tname != 'shallow_water' && tname != 'void' &&
      tname != 'swamp' && tname != 'bridge';
    }
  }
});
