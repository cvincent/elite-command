var SpriteCount = 0;
var SpriteLayer = 2;

var Sprite = new JS.Class({
  initialize: function(sprite_sheet) {
    SpriteCount += 1;

    this.dom_id = 'sprite_' + SpriteCount;
    this.sprite_sheet = sprite_sheet;

    this.map = null;
    this.x = null;
    this.y = null;

    this.e = $('<div id="' + this.dom_id + '"></div>');
    this.e.css('position', 'absolute');

    this.sprite_sheet.set_state(this.e, 0, 0);
    this.set_layer(SpriteLayer);
  },

  add_to_map: function(map, x, y) {
    if (x == undefined) x = this.x;
    if (y == undefined) x = this.y;

    if (this.map != null) this.remove();

    this.map = map;
    this.map.e.append(this.e);
    this.e.show();

    this.set_layer(this.layer);

    if (x != undefined && x != null && y != undefined && y != null) {
      this.set_position(x, y);
    }
  },

  set_position: function(x, y) {
    this.x = x;
    this.y = y;

    var pos = Map.tile_to_pixel_coords(x, y);
    this.e.css('left', pos[0] + 'px');
    this.e.css('top',  pos[1] + 'px');
  },

  set_layer: function(layer) {
    this.layer = layer;
    this.e.css('z-index', layer);
  },

  set_sprite: function(x, y) {
    this.sprite_sheet.set_state(this.e, x, y);
  },

  remove: function() {
    this.map = null;
    this.e.remove();
  }
});
