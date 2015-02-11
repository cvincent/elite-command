var Dialog = new JS.Class({
  initialize: function() {
    this.content = $('<div></div>');
    this.content.dialog({
      modal: true, closeOnEscape: false, resizable: false, autoOpen: false, width: 400
    });
  },

  open: function() {
    this.content.dialog('open');
    $('.ui-dialog-content').attr('style', '');
    $('.ui-widget-overlay').css('z-index', 10003)
    $('.ui-dialog').css('z-index', 10004)
  },

  close: function() {
    this.content.remove();
    this.content.dialog('close');
  }
});
