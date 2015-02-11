function MapEditor(game_state) {
  this.game_state = game_state
  
  this.mode = 'tile'
  this.selected_player = Game.neutral_player
  this.draw_tile = 0
  this.drawing = false
  
  this.game_state.map.set_event_handler(this)
  this.game_state.map.disable_drag_scroll = true
  
  $(this.game_state.map.map_dom_id).css('cursor', 'crosshair')
  
  this.tile_click = function(x, y) {
    //this.tile(x, y).set_type(draw_tile)
    //this.draw()
  }
  
  this.tile_mousedown = function(x, y) {
    if (this.mode == 'tile') {
      this.game_state.map.tile(x, y).set_type(this.draw_tile)
      this.game_state.map.draw_tile(x, y)
      this.drawing = true
    } else if (this.mode == 'delete') {
      var unit = this.game_state.unit_at_position(x, y)
      var base = this.game_state.base_at_position(x, y)
      
      if (unit) {
        this.game_state.remove_unit(unit)
      } else if (base) {
        this.game_state.remove_base(base)
      }
    } else if (this.mode == 'Base' || this.mode == 'Airfield' || this.mode == 'Seaport') {
      var old_base = this.game_state.base_at_position(x, y)
      if (old_base) this.game_state.remove_base(old_base)
      
      this.game_state.map.tile(x, y).set_type(0)
      this.game_state.map.draw_tile(x, y)
      this.game_state.bases.push(new Base(this.selected_player, this.mode, this.game_state.map, x, y, false))
    } else {
      if (UnitDefinitions[this.mode].movement[this.game_state.map.tile(x, y).tile_type.name] < 99) {
        var old_unit = this.game_state.unit_at_position(x, y)
        if (old_unit) this.game_state.remove_unit(old_unit)
        
        this.game_state.units.push(new Unit(this.selected_player, this.mode, this.game_state.map, x, y))
      }
    }
  }
  
  this.tile_mouseup = function(x, y) {
    this.drawing = false
  }
  
  this.tile_mousemove = function(x, y) {
    if (this.drawing) {
      this.game_state.map.tile(x, y).set_type(this.draw_tile)
      this.game_state.map.draw_tile(x, y)
    }
  }
  
  this.set_selected_player = function() {
    var selection = parseInt($('#selected_player').val())
    if (selection == -1) this.selected_player = this.game_state.neutral_player; else this.selected_player = this.game_state.players[selection]
    selection += 1
    $('.player_button').css('background-position-y', '-' + (selection * 34) + 'px')
  }
  
  this.serialize = function() {
    this.serialize_map_data()
    this.serialize_base_data()
    this.serialize_unit_data()
    return true
  }
  
  this.serialize_map_data = function() {
    $('#map_data_field').val(this.game_state.map.serialize())
  }
  
  this.serialize_base_data = function() {
    $('#bases_field').val(this.game_state.serialize_bases())
  }
  
  this.serialize_unit_data = function() {
    $('#units_field').val(this.game_state.serialize_units())
  }
}
