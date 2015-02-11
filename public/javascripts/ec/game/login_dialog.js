var LoginDialog = new JS.Class(Dialog, {
  initialize: function(r) {
    var me = this;
    this.callSuper();

    var html = '';

    html += '<h3>Login</h3>';
    html += '<p>Login with your Elite Command credentials.</p>';

    html += '<form action="/users/login" method="post">';
    html += '  <table>';
    html += '    <tr><th><label>Username:</label></th><td><input type="text" name="username"/></td></tr>';
    html += '    <tr><th><label>Password:</label></th><td><input type="password" name="password"/></td></tr>';
    html += '  </table>';
    html += '  <p style="text-align: right">';
    html += '    <input type="hidden" value="' + r + '" name="r"/>'
    html += '    <input type="hidden" value="' + AUTH_TOKEN + '" name="authenticity_token"/>';
    html += '    <input type="submit" value="Login" class="main"/>';
    html += '    <input type="button" value="Cancel" id="cancel_login"/>';
    html += '  </p>';
    html += '</form>';

    this.content.append(html);

    this.content.find("#cancel_login").click(function() {
      me.close();
      return false;
    });
  }
});
