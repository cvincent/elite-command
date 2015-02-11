var OrbitedController = new JS.Class({
  initialize: function() {
    this.subscriptions = new JS.Hash();
  },

  received_data: function(data) {
    var msg = null;
    eval('msg = ' + data.body);

    this.relay_message(msg);
  },

  relay_message: function(message) {
    var subscribers = this.subscriptions.get(message.msg_class);

    if (subscribers) {
      subscribers.forEach(function(subscriber) {
        subscriber[0][subscriber[1]](message);
      }, this);
    }
  },

  add_subscription: function(msg_class, obj, callback) {
    var subscribers = this.subscriptions.get(msg_class);

    if (subscribers) {
      this.subscriptions.get(msg_class).add([obj, callback]);
    } else {
      this.subscriptions.put(msg_class, new JS.Set([[obj, callback]]));
    }
  }
});
