var TmPlainsSprite = new JS.Class(Sprite, {
  initialize: function() {
    this.callSuper(SpriteSheets.terrains);
    this.set_sprite('terrain', 'plains');
  },

  add_to_map: function(map) {
    this.callSuper(map);
    $('#tile_x_' + this.x + '_y_' + this.y).hide()
      .attr('id', 'tile_x_' + this.x + '_y_' + this.y + '_old');
    this.e.attr('id', 'tile_x_' + this.x + '_y_' + this.y);
  },

  remove: function() {
    this.callSuper();
    $('#tile_x_' + this.x + '_y_' + this.y + '_old').show()
      .attr('id', 'tile_x_' + this.x + '_y_' + this.y);
  },

  update_for_surrounding_terrain: function(surrounding) {
    // No-op
  }
});

