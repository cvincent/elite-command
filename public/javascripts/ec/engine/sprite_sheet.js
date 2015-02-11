var SpriteSheet = new JS.Class({
  initialize: function(src, w, h, xname, yname, xvals, yvals) {
    this.src = src;
    this.sprite_w = w;
    this.sprite_h = h;
    this.xvals = xvals;
    this.yvals = yvals;
  },

  set_state: function(e, x, y) {
    var xi = this.index('x', x) * this.sprite_w;
    var yi = this.index('y', y) * this.sprite_h;

    e.css('background-image', 'url(' + this.src + ')');
    e.css('background-repeat', 'no-repeat');
    e.css('background-position', '-' + xi + 'px -' + yi + 'px');
    e.css('width', this.sprite_w);
    e.css('height', this.sprite_h);
  },

  index: function(axis, i) {
    if (typeof(i) == 'number') {
      return i;
    } else {
      return (axis == 'x' ? $.inArray(i, this.xvals) : $.inArray(i, this.yvals));
    }
  }
});
