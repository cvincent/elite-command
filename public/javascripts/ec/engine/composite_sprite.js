var CompositeSprite = new JS.Class(Sprite, {
  initialize: function() {
    this.sprites = new JS.Set([]);
    this.layer = 0;
    this.set_layer(SpriteLayer);
  },

  add_sprite: function(sprite) {
    this.sprites.add(sprite);
  },

  remove_sprite: function(sprite) {
    this.sprites.remove(sprite);
  },

  add_to_map: function(map, x, y) {
    this.sprites.forEach(function(sprite) {
      sprite.add_to_map(map, x, y);
      this.set_layer(this.layer);
    }, this);
  },

  set_position: function(x, y) {
    this.x = x;
    this.y = y;

    this.sprites.forEach(function(sprite) {
      sprite.set_position(x, y);
    }, this);
  },

  set_layer: function(layer) {
    var diff = layer - this.layer;
    this.layer = layer;

    this.sprites.forEach(function(sprite) {
      sprite.set_layer(sprite.layer + diff);
    }, this);
  },

  remove: function() {
    this.sprites.forEach(function(sprite) {
      sprite.remove();
    }, this);
  },

  selector: function() {
    var sel = '';

    this.sprites.forEach(function(sprite) {
      if (sel != '') sel += ', ';
      sel += '#' + sprite.e.attr('id');
    }, this);

    return sel;
  }
});
