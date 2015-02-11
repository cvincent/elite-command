var HCoordinate = new JS.Class({
  initialize: function(x, y) {
    this.x = x;
    this.y = y;
  },

  equals: function(other) {
    return this.x == other.x && this.y == other.y;
  },

  hash: function() {
    return this.x + ',' + this.y;
  }
});
