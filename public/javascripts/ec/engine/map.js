var TileLayer = 1;
var TilesetUrl = '/images/game/tileset.png';

var TileSize = 32
var TileSizeH = 8
var TileSizeS = 18
var TileSizeR = 16

var Map = new JS.Class({
  initialize: function(dom_id, tiles) {
    $('body').attr('onSelectStart', 'return false');

    this.dom_id = '#' + dom_id;
    this.e = $(this.dom_id);
    this.tiles = tiles;
    this.tiles_width = tiles[0].length;
    this.tiles_height = tiles.length;

    this.event_catcher = $('<div id="' + dom_id + '_event_catcher"></div>')
      .insertAfter(this.e);
    this.event_handler = this;
    this.mouse_drag_start = null;
    this.started_dragging = false;
    this.disable_drag_scroll = false;

    this.e.css('overflow', 'hidden');
    this.event_catcher.css('position', 'absolute');
    this.event_catcher.css('top', this.e.css('top'));
    this.event_catcher.css('left', this.e.css('left'));
    this.event_catcher.css('height', this.e.css('height'));
    this.event_catcher.css('width', this.e.outerWidth());
    this.event_catcher.css('z-index', 99);

    // This should be smarter and calculate the number of visible tiles
    // using the CSS height and width properties
    if (this.tiles_width > 20 || this.tiles_height > 20) {
      this.event_catcher.append('<div id="scroll_message">Click and drag to pan the map, or use your mousewheel (hold Shift for horizontal).</div>')
    }

    this.initialize_tiles_hash();

    var self = this;

    this.event_catcher.click(function(ev) {
      if (!self.started_dragging) {
        var coords = self.scroll_to_map_coords(ev.pageX, ev.pageY);
        var tile_coords = Map.pixel_to_tile_coords(coords[0], coords[1]);

        self.event_handler.tile_click(tile_coords[0], tile_coords[1]);
      }
    });

    this.event_catcher.mousewheel(function(ev, d) {
      $.browser.safari = ( $.browser.safari && /chrome/.test(navigator.userAgent.toLowerCase()) ) ? false : true;

      var scroll = -d;
      if (($.browser.webkit && !$.browser.safari) || $.browser.mozilla) {
        scroll *= 100;
      }

      var direction = ev.shiftKey ? 'scrollLeft' : 'scrollTop';

      self.e.attr(direction, self.e.attr(direction) + scroll);

      ev.preventDefault();
    });

    this.event_catcher.mousedown(function(ev) {
      var coords = self.scroll_to_map_coords(ev.pageX, ev.pageY);
      var x = coords[0]; var y = coords[1];

      if (!self.disable_drag_scroll) {
        self.mouse_drag_start = [x, y];
        self.started_dragging = false;
      } else {
        var tile_coords = Map.pixel_to_tile_coords(coords[0], coords[1]);
        self.event_handler.tile_mousedown(tile_coords[0], tile_coords[1]);
      }
    });

    this.event_catcher.mouseup(function(ev) {
      var coords = self.scroll_to_map_coords(ev.pageX, ev.pageY);
      var x = coords[0]; var y = coords[1];
      self.mouse_drag_start = null;
      document.body.style.cursor = 'default'

      if (self.disable_drag_scroll) {
        var tile_coords = Map.pixel_to_tile_coords(coords[0], coords[1]);
        self.event_handler.tile_mouseup(tile_coords[0], tile_coords[1]);
      }
    });

    this.event_catcher.mousemove(function(ev) {
      var coords = self.scroll_to_map_coords(ev.pageX, ev.pageY);
      var x = coords[0]; var y = coords[1];

      if (self.mouse_drag_start) {
        var dx = x - self.mouse_drag_start[0];
        var dy = y - self.mouse_drag_start[1];
        self.started_dragging = true;
        document.body.style.cursor = 'move'

        self.e.attr('scrollLeft', self.e.attr('scrollLeft') - dx);
        self.e.attr('scrollTop',  self.e.attr('scrollTop')  - dy);
      }

      var tile_coords = Map.pixel_to_tile_coords(coords[0], coords[1]);
      self.event_handler.tile_mousemove(tile_coords[0], tile_coords[1]);
    });
  },

  tile_click: function(x, y) {
    console.log('click ' + tile_coords[0] + ', ' + tile_coords[1]);
  },

  initialize_tiles_hash: function() {
    this.tiles_hash = new JS.Hash(null);

    for (var x = 0; x < this.tiles_width; x++) {
      for (var y = 0; y < this.tiles_height; y++) {
        this.tiles_hash.put(new HCoordinate(x, y), this.tile_index(x, y));
      }
    }
  },

  scroll_to_map_coords: function(x, y) {
    var mx = x - this.e.offset().left + this.e.attr('scrollLeft') - parseInt(this.e.css('border-left-width'));
    var my = y - this.e.offset().top  + this.e.attr('scrollTop') - parseInt(this.e.css('border-top-width'));

    return [mx, my];
  },

  set_event_handler: function(handler) {
    this.event_handler = handler;
  },

  tile_index: function(x, y) {
    try {
      return this.tiles[y][x];
    } catch(err) {
      return null;
    }
  },

  draw: function() {
    for (var x = 0; x < this.tiles_width; x++) {
      for (var y = 0; y < this.tiles_height; y++) {
        this.redraw_tile(x, y);
      }
    }
  },

  redraw_tile: function(x, y) {
    var tile_id = 'tile_x_' + x + '_y_' + y;
    $('#' + tile_id).remove();

    var tile_index = this.tile_index(x, y);
    var dom_tile = Map.element_for_tile_index(tile_index);
    dom_tile.attr('id', tile_id);

    var coords = Map.tile_to_pixel_coords(x, y);
    dom_tile.css('left', coords[0] + 'px');
    dom_tile.css('top',  coords[1] + 'px');
    dom_tile.css('text-align', 'center');
    dom_tile.css('font-size', '8px');
    dom_tile.css('line-height', '34px');
    // dom_tile.text(x + ', ' + y);

    this.e.append(dom_tile);
    dom_tile.show();
  },

  extend: {
    element_for_tile_index: function(idx) {
      var e = $("<div></div>");

      e.css('position', 'absolute');
      e.css('background-repeat', 'no-repeat');
      e.css('background-image', 'url(' + TilesetUrl + ')');
      e.css('background-position', '-' + (idx * TileSize) + 'px 0');
      e.css('width', TileSize);
      e.css('height', TileSizeS + (2 * TileSizeH));
      e.css('z-index', TileLayer);
      e.attr('onSelectStart', 'return false');
      e.addClass('tile');
      e.hide();

      return e;
    },

    tile_to_pixel_coords: function(tx, ty) {
      var px = 0;
      var py = ty * (TileSizeH + TileSizeS);

      if (ty % 2 == 0) {
        px = tx * 2 * TileSizeR;
      } else {
        px = tx * 2 * TileSizeR + TileSizeR;
      }

      return [px, py];
    },

    pixel_to_tile_coords: function(px, py) {
      var tx = null;
      var ty = null;

      var sx = parseInt(px / (2 * TileSizeR));
      var sy = parseInt(py / (TileSizeH + TileSizeS));

      var spx = px % (2 * TileSizeR);
      var spy = py % (TileSizeH + TileSizeS);

      var section_type = '';

      if (sy % 2 == 0) section_type = 'A'; else section_type = 'B';

      var m = TileSizeH / TileSizeR;

      if (section_type == 'A') {
        tx = sx;
        ty = sy;

        if (spy < (TileSizeH - (spx * m))) {
          tx = sx - 1;
          ty = sy - 1;
        }
        if (spy < (-TileSizeH + (spx * m))) {
          tx = sx;
          ty = sy - 1;
        }
      } else {
        if (spx >= TileSizeR) {
          if (spy < (2 * TileSizeH - (spx * m))) {
            tx = sx;
            ty = sy - 1;
          } else {
            tx = sx;
            ty = sy;
          }
        } else {
          if (spy < spx * m) {
            tx = sx;
            ty = sy - 1;
          } else {
            tx = sx - 1;
            ty = sy;
          }
        }
      }

      return [tx, ty];
    }
  }
});
