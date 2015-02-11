var CompositeGameCommand = new JS.Class(GameCommand, {
  initialize: function(game, user, params) {
    this.callSuper(game, user, params);
    this.subcommands = [];
  },

  add_command: function(subcommand) {
    this.subcommands.push(subcommand);
  },

  add_and_execute_command: function(subcommand) {
    this.subcommands.push(subcommand);
    subcommand.execute();
  },

  remove_and_unexecute_last_command: function() {
    var cmd = this.subcommands.pop();
    cmd.unexecute();
  },

  command_count: function() {
    return this.subcommands.length;
  },

  execute: function() {
    for (var i in this.subcommands) {
      this.subcommands[i].execute();
    }
  },

  replay: function() {
    for (var i in this.subcommands) {
      this.subcommands[i].replay();
    }
  },

  unexecute: function() {
    for (var i = this.subcommands.length - 1; i >= 0; i--) {
      this.subcommands[i].unexecute();
    }
  },

  commit: function(callback_object, callback) {
    var cmds = [];
    var me = this;

    for (var i in this.subcommands) {
      var p = this.subcommands[i].params;
      if (p == null) p = {};
      p.command = this.subcommands[i].class_name();
      cmds.push(p);
    }

    $.post(
      '/games/' + this.game.id + '/execute_command', { commands: cmds },
      function(data) {
        for (var i = 0; i < me.subcommands.length; i++) {
          me.subcommands[i].post_commit(data.result[i]);
        }

        if (callback_object && callback) {
          callback_object[callback]();
        }
      }
    );
  },

  finish: function() {
    for (var i = 0; i < this.subcommands.length; i++) {
      this.subcommands[i].finish();
    }
  },

  extend: {
    new_from_json: function(json, game, user) {
      var composite = new CompositeGameCommand(game, user, json.params);

      for (var i in json.subcommands) {
        composite.add_command(GameCommand.new_from_json(json.subcommands[i], game, user));
      }

      return composite;
    }
  },

  can_undo: function() {
    for (var i in this.subcommands) {
      if (!this.subcommands[i].can_undo()) return false;
    }

    return true;
  },

  rewind: function() {
    for (var i = this.subcommands.length - 1; i >= 0; i--) {
      this.subcommands[i].rewind();
    }
  }
});
