var BaseLayer = 4;
var FlagLayer = 7;

var Base = new JS.Class(CompositeSprite, {
  initialize: function(base_json) {
    this.callSuper();

    this.base_type = base_json.base_type;
    this.player = base_json.player;
    this.player_id = base_json.player_id;

    this.capture_player = base_json.capture_player;
    this.capture_player_id = base_json.capture_player_id;

    this.base = new Sprite(SpriteSheets.bases);
    this.base.set_sprite(this.base_type, this.player);
    this.base.set_layer(BaseLayer);
    this.add_sprite(this.base);

    this.capture_indicator = new Sprite(SpriteSheets.base_capturing);
    this.capture_indicator.set_layer(FlagLayer);
    this.add_sprite(this.capture_indicator);

    if (base_json.x != undefined && base_json.y != undefined) this.set_position(base_json.x, base_json.y);
    this.set_capture_phase(base_json.capture_phase);
  },

  to_json: function() {
    var j = {
      base_type: this.base_type, capture_phase: this.capture_phase,
      capture_player_id: this.capture_player_id, player: this.player,
      player_id: this.player_id, x: this.x, y: this.y
    }
    return j;
  },

  add_to_map: function(map) {
    this.callSuper();
    this.set_capture_phase(this.capture_phase);
  },

  start_capture: function(capture_player, capture_player_id) {
    this.capture_player = capture_player;
    this.capture_player_id = capture_player_id;
    this.set_capture_phase(1);
  },

  continue_capture: function() {
    var phase = this.capture_phase - 1;
    this.set_capture_phase(phase);

    if (phase < 0) {
      this.player_id = this.capture_player_id;
      this.player = this.capture_player;
      this.capture_phase = null;
      this.capture_player_id = null;
      this.capture_player = null;

      this.base.set_sprite(this.base_type, this.player);

      return true;
    } else {
      return false;
    }
  },

  cancel_capture: function() {
    this.capture_player = null;
    this.capture_player_id = null;
    this.set_capture_phase(null);
  },

  set_capture_phase: function(phase) {
    this.capture_phase = phase;

    if (this.capture_phase != null && this.capture_phase >= 0) {
      this.capture_indicator.e.show();
      this.capture_indicator.e.css('z-index', 10);
    } else {
      this.capture_indicator.e.hide();
    }
  },

  set_player: function(player_num) {
    this.player = player_num;
    this.base.set_sprite(this.base_type, this.player);
  }
});
