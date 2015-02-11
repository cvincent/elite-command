var TerrainModifierLayer = 4;

var TerrainModifier = new JS.Class({
  initialize: function(json) {
    this.terrain_name = json.terrain_name;
    this.x = json.x;
    this.y = json.y;

    var sprite_klass = 'Tm' + json.terrain_name.camelize() + 'Sprite';
    sprite_klass = window[sprite_klass];

    this.sprite = new sprite_klass();
  },

  to_json: function() {
    var j = {
      terrain_name: this.terrain_name, x: this.x, y: this.y
    }

    return j;
  },

  add_to_map: function(map) {
    this.sprite.add_to_map(map, this.x, this.y);
    this.sprite.set_layer(TerrainModifierLayer);
  },

  remove: function() {
    this.sprite.remove();
  },

  update_for_surrounding_terrain: function(surrounding) {
    this.sprite.update_for_surrounding_terrain(surrounding);
  }
});
