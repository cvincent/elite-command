var BuildDialog = new JS.Class(Dialog, {
  initialize: function(what, unit, avail_creds, event_handler, confirm_method, cancel_method) {
    this.callSuper();

    var title = 'Build ' + what + '?';
    if (what == 'plains') title = 'Clear woods?';
    if (what == 'destroy') title = 'Destroy improvement?';

    var turns = unit.def.can_build[what].turns;
    if (turns == 0 || turns > 1) turns = '<strong>' + turns + ' turns</strong>';
    if (turns == 1) turns = '<strong>1 turn</strong>';

    var credits = unit.def.can_build[what].credits;
    var creds = credits;
    if (credits > 0) credits = ' and cost you <strong>' + credits + ' credits</strong>';
    if (credits <= 0) credits = '';

    this.content.append('<h3>' + title + '</h3>');
    this.content.append('<p>This will take your unit ' + turns + credits + '.</p>');

    if (avail_creds < creds) {
      this.content.append('<p>You do not have enough credits.</p>');
    }

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    if (avail_creds >= creds) {
      var confirm_button = $('<button class="main">Proceed</button>').click(function() {
        event_handler[confirm_method]();
      });
      buttons.append(confirm_button);
    } else {
      var confirm_button = $('<button class="main" disabled="disabled">Proceed</button>');
      buttons.append(confirm_button);
    }

    var cancel_button = $('<button>Cancel</button>').click(function() {
      event_handler[cancel_method]();
    });
    buttons.append(cancel_button);

    this.content.append(buttons);
  }
});
