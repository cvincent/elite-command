var CaptureBaseDialog = new JS.Class(Dialog, {
  initialize: function(event_handler, confirm_method, wait_method, cancel_method) {
    this.callSuper();
    this.content.append('<h3>Capture base?</h3>');
    this.content.append('<p>Capturing a base takes two turns. The capturing unit must survive, and will be consumed if the base is successfully captured. The unit will suffer a -2 armor penalty and cannot be given any commands while capturing.</p>');

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    var capture_button = $('<button class="main">Capture</button>').click(function() {
      event_handler[confirm_method]();
    });
    buttons.append(capture_button);

    var wait_button = $('<button>Wait</button>').click(function() {
      event_handler[wait_method]();
    });
    buttons.append(wait_button);

    var cancel_button = $('<button>Cancel</button>').click(function() {
      event_handler[cancel_method]();
    });
    buttons.append(cancel_button);

    this.content.append(buttons);
  }
});
