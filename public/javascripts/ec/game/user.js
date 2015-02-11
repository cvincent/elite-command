var User = new JS.Class({
  initialize: function(user_data) {
    if (user_data == null) user_data = {};
    this.id = user_data._id;
    this.username = user_data.username;
    this.rating = user_data.rating;
  },

  equals: function(other) {
    if (other != undefined && other != null) {
      return other.id == this.id;
    } else {
      return false;
    }
  }
});
