var InviteDialog = new JS.Class(Dialog, {
  initialize: function(current_user, game, end_turn_message) {
    var me = this;
    this.cursor = null;

    this.callSuper();
    this.content.append('<h3>Invite players</h3>');

    if (end_turn_message) {
      this.content.append('<p>Another player is needed to continue this game. You can wait for someone to join or invite a friend!');
    }

    var cancel_button = $('<button>Close</button>');
    var cancel_click = function() {
      me.close();
      return false;
    }

    var tabs = $('<div class="dialog_tabs"></div>');

    var email_tab = $('<a href="#">Via Email</a>');
    email_tab.click(function() { me.set_tab(this, 'email'); return false; });
    tabs.append(email_tab);

    var ec_tab = $('<a href="#">Existing Player</a>');
    ec_tab.click(function() { me.set_tab(this, 'ec'); return false; });
    tabs.append(ec_tab);

    this.content.append(tabs);



    // EMAIL TAB

    var email_tab_content = $('<div id="email_tab_content" class="tab_content" style="display: none;"></div>');
    var email_form = $('<form method="post"></form>');
    var email_form_fields = $('<dl></dl>');
    email_form_fields.append($('<dt>Your name (will appear in email):</dt><dd><input type="text" name="inviter_name" value="' + current_user.username + '" size="40"/></dd>'));
    email_form_fields.append($('<dt>Invitee email:</dt><dd><input type="text" name="invitee_email" size="40"/></dd>'));
    email_form_fields.append($('<dt>Message:</dt><dd><textarea cols="40" rows="2" type="text" name="message" id="ec_message">Play Elite Command with me!</textarea></dd>'));
    email_form_fields.append($('<p style="text-align: right"><input type="submit" value="Send Invite" class="main"/></p>').append(cancel_button.clone().click(cancel_click)));
    email_form.append(email_form_fields);
    email_form.attr('action', '/games/' + game.id + '/invite_via_email');
    email_tab_content.append(email_form);

    email_form.submit(function() {
      me.content.find('button, input[type=submit]').attr('disabled', true);
      me.content.find('.temp_flash').remove();

      $.post($(this).attr('action'), $(this).serialize(), function(data) {
        if (data.success) {
          var success = $('<p class="temp_flash flash_notice">Your invite has been sent.</p>');
          me.content.find('h3').after(success);
        } else {
          var failure = $('<ul class="temp_flash errors"></ul>');
          for (var i in data.errors) {
            failure.append('<li>' + data.errors[i] + '</li>');
          }
          me.content.find('h3').after(failure);
        }

        me.content.find('button, input').attr('disabled', false);
      });
      return false;
    });

    this.content.append(email_tab_content);



    // EC TAB

    var ec_tab_content = $('<div id="ec_tab_content" class="tab_content" style="display: none;"></div>');
    var ec_form = $('<form method="post"></form>');
    var ec_form_fields = $('<dl></dl>');

    var ec_autocomplete = $('<input type="text" name="username" id="ec_username" placeholder="Start typing a username..." size="40" autocomplete="off"/>');
    ec_autocomplete.keyup(function(e) {
      var f = $(this);

      if (e.which == 40) { // Down arrow
        if (me.cursor == null) {
          $('#ec_autocomplete a:first-child').addClass('cursor');
          me.cursor = true;
        } else {
          var c = $('#ec_autocomplete a.cursor');
          if (c.next().length > 0) {
            c.removeClass('cursor');
            c.next().addClass('cursor');
          }
        }

      } else if (e.which == 38) { // Up arrow
        var c = $('#ec_autocomplete a.cursor');
        if (c.prev().length > 0) {
          c.removeClass('cursor');
          c.prev().addClass('cursor');
        }

      } else if (e.which == 13) { // Return
        var c = $('#ec_autocomplete a.cursor');
        if (c.length > 0) {
          me.select_username(c.text());
        }

      } else {
        me.cursor = null;

        if (f.val() != '') {
          $.get('/users/usernames', { autocomplete_from: f.val() }, function(data) {
            $('#ec_autocomplete').show()
              .css('top', (f.offset().top - f.offsetParent().offset().top) + 22)
              .css('left', (f.offset().left - f.offsetParent().offset().left))
              .css('width', (parseInt(f.css('width')) - 4) || 150)
              .empty();

            for (var i in data.users) {
              var user = $('<a href="#">' + data.users[i] + '</a>').mousedown(function() {
                me.select_username($(this).text());
              });
              $('#ec_autocomplete').append(user);
            }
          });
        }
      }
    });

    ec_autocomplete.blur(function() { $('#ec_autocomplete').hide(); me.cursor = null; });

    ec_autocomplete.keydown(function(ev) {
      if (ev.which == 40 || ev.which == 38 || ev.which == 13) {
        ev.preventDefault();
      }
    });
    
    ec_form_fields.append('<dt>User:</dt>').append($('<dd></dd>').append(ec_autocomplete));

    ec_form_fields.append($('<dt>Message:</dt><dd><textarea cols="40" rows="2" type="text" name="message">Play Elite Command with me!</textarea></dd>'));
    ec_form_fields.append($('<p style="text-align: right"><input type="submit" value="Send Invite" class="main"/></p>').append(cancel_button.clone().click(cancel_click)));
    ec_form.append(ec_form_fields);
    ec_form.attr('action', '/games/' + game.id + '/invite_via_ec');

    ec_form.submit(function() {
      me.content.find('button, input[type=submit]').attr('disabled', true);
      me.content.find('.temp_flash').remove();

      $.post($(this).attr('action'), $(this).serialize(), function(data) {
        if (data.success) {
          var success = $('<p class="temp_flash flash_notice">Your invite has been sent.</p>');
          me.content.find('h3').after(success);
        } else {
          var failure = $('<ul class="temp_flash errors"></ul>');
          for (var i in data.errors) {
            failure.append('<li>' + data.errors[i] + '</li>');
          }
          me.content.find('h3').after(failure);
        }

        me.content.find('button, input').attr('disabled', false);
      });
      return false;
    });

    ec_tab_content.append(ec_form);
    ec_tab_content.append($('<div id="ec_autocomplete" style="position: absolute; display: none"></div>'));



    // DONE

    this.content.append(ec_tab_content);

    this.set_tab(email_tab, 'email');
  },

  set_tab: function(tab_link, tab_name) {
    $('.current_tab').removeClass('current_tab');
    $(tab_link).addClass('current_tab');
    $('.current_tab_content').hide();
    $('#' + tab_name + '_tab_content').addClass('current_tab_content').show();
  },

  select_username: function(username) {
    $('#ec_autocomplete').hide();
    $('#ec_username').val(username);
    $('#ec_username').blur();
    $('#ec_message').focus();
  }
});
