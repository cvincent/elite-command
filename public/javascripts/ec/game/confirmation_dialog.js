var ConfirmationDialog = new JS.Class(Dialog, {
  initialize: function(title, desc, confirm_name, callback_obj, callback) {
    var me = this;

    this.callSuper();
    this.callback_obj = callback_obj;
    this.callback = callback;

    this.content.append('<h3>' + title + '</h3>');
    this.content.append('<p>' + desc + '</p>');

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    var confirm_button = $('<button>' + confirm_name + '</button>');
    confirm_button.addClass('main');
    confirm_button.click(function() {
      me.callback_obj[me.callback]();
      me.close();
    });

    var cancel_button = $('<button>Cancel</button>');
    cancel_button.click(function() {
      me.close();
    });

    buttons.append(confirm_button);
    buttons.append(cancel_button);

    this.content.append(buttons);
  },

  extend: {
    show: function(title, desc, confirm_name, callback_obj, callback) {
      var dialog = new ConfirmationDialog(title, desc, confirm_name, callback_obj, callback);
      dialog.open();
    }
  }
});
