var LoadedUnitsDialog = new JS.Class(Dialog, {
  initialize: function(unit, event_handler, confirm_method, cancel_method) {
    this.callSuper();

    var me = this;

    this.unit = unit;
    this.event_handler = event_handler;
    this.confirm_method = confirm_method;
    this.cancel_method = cancel_method;

    this.content.append('<h3>Disembark a unit?</h3>');
    this.content.append('<p>You will be able to move the unit with any remaining movement points it has.</p>');

    var sprites = $('<div id="loaded_units_dialog_sprites"></div>');

    for (var i in unit.loaded_units) {
      var u = unit.loaded_units[i];
      var sprite = this.create_unit_link(u, i);
      var us = u.unit.e.clone().show().css('position', 'absolute').css('top', 0).css('left', 0);
      var h = u.health_indicator.e.clone().show().css('position', 'absolute').css('top', 0).css('left', 0);
      var m = u.movement_indicator.e.clone().show().css('position', 'absolute').css('top', 0).css('left', 0);
      var a = u.attacks_indicator.e.clone().show().css('position', 'absolute').css('top', 0).css('left', 0);
      
      sprite.append(us).append(h).append(m).append(a);
      sprites.append(sprite);
    }

    this.content.append(sprites);

    var buttons = $('<p></p>');
    buttons.css('text-align', 'right');

    var cancel_button = $('<button>Cancel</button>');
    cancel_button.click(function() {
      me.event_handler[me.cancel_method]();
      return false;
    });
    buttons.append(cancel_button);

    this.content.append(buttons);
  },

  create_unit_link: function(unit, slot) {
    var me = this;

    var a = $('<a class="loaded_unit_sprite" href="#"></a>');
    a.click(function() {
      me.event_handler[me.confirm_method](unit, slot);
      return false;
    });

    return a;
  }
});
