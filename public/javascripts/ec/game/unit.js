var UnitLayer = 6;
var OverlayLayer = 8;

var Unit = new JS.Class(CompositeSprite, {
  initialize: function(unit_json) {
    this.callSuper();

    this.def = GameConfig.units[unit_json.unit_type];

    this.unit_type = unit_json.unit_type;
    this.player = unit_json.player;
    this.player_id = unit_json.player_id;
    this.flank_penalty = unit_json.flank_penalty || 0;

    this.loaded_units = [];
    for (var i in unit_json.loaded_units) {
      this.loaded_units.push(new Unit(unit_json.loaded_units[i]));
    }

    this.unit = new Sprite(SpriteSheets.units);
    this.unit.set_sprite(this.unit_type + 'Right', this.player);
    this.unit.set_layer(UnitLayer);
    this.add_sprite(this.unit);

    this.health_indicator = new Sprite(SpriteSheets.health);
    this.health_indicator.set_layer(OverlayLayer);
    this.add_sprite(this.health_indicator);

    this.movement_indicator = new Sprite(SpriteSheets.movement);
    this.movement_indicator.set_layer(OverlayLayer);
    this.add_sprite(this.movement_indicator);

    this.attacks_indicator = new Sprite(SpriteSheets.attacks);
    this.attacks_indicator.set_layer(OverlayLayer);
    this.add_sprite(this.attacks_indicator);

    this.transport_indicator = new Sprite(SpriteSheets.transport_capacity);
    this.transport_indicator.set_layer(OverlayLayer);
    this.add_sprite(this.transport_indicator);

    this.building_indicator = new Sprite(SpriteSheets.unit_building);
    this.building_indicator.set_layer(OverlayLayer);
    this.add_sprite(this.building_indicator);

    if (unit_json.x != undefined && unit_json.y != undefined) this.set_position(unit_json.x, unit_json.y);
    this.set_health(unit_json.health || 10);
    this.set_movement_points(
      unit_json.movement_points == undefined ? this.def.movement_points : unit_json.movement_points
    );
    this.set_attacks(unit_json.attacks || 0);
    this.attacked = unit_json.attacked;
    this.healed = unit_json.healed;
    this.set_transport_capacity();
    this.set_build_phase(unit_json.build_phase);

    this.current_build = unit_json.current_build;

    this.moved = unit_json.moved;
  },

  to_json: function() {
    var j = {
      attacks: this.attacks, flank_penalty: this.flank_penalty, health: this.health,
      loaded_units: [], moved: this.moved, movement_points: this.movement_points,
      player: this.player, player_id: this.player_id, summoning_sickness: this.summoning_sickness,
      unit_type: this.unit_type, x: this.x, y: this.y
    }

    for (var i in this.loaded_units) {
      j.loaded_units.push(this.loaded_units[i].to_json());
    }

    return j;
  },

  add_to_map: function(map) {
    this.callSuper(map, this.x, this.y, this.layer);
    this.set_build_phase(this.build_phase);
  },

  set_position: function(x, y) {
    var old_px = Map.tile_to_pixel_coords((this.x || 0), (this.y || 0))[0];
    var new_px = Map.tile_to_pixel_coords(x, y)[0];
    var facing = (new_px < old_px ? 'Left' : 'Right');

    if (old_px != new_px) this.unit.set_sprite(this.unit_type + facing, this.player);

    this.callSuper(x, y);
  },

  face_unit: function(unit) {
    var tx = Map.tile_to_pixel_coords((this.x || 0), (this.y || 0))[0];
    var ux = Map.tile_to_pixel_coords((unit.x || 0), (unit.y || 0))[0];
    var facing = (ux < tx ? 'Left' : 'Right');

    if (ux != tx) this.unit.set_sprite(this.unit_type + facing, this.player);
  },

  face_right: function() {
    this.unit.set_sprite(this.unit_type + 'Right', this.player);
  },

  face_left: function() {
    this.unit.set_sprite(this.unit_type + 'Left', this.player);
  },

  set_health: function(health) {
    this.health = health;
    this.health_indicator.set_sprite(0, 10 - health);
  },

  set_movement_points: function(mv) {
    this.movement_points = mv;

    var level = 0;
    if (mv == 0) level = 2;
    else if (mv < this.def.movement_points) level = 1;

    this.movement_indicator.set_sprite(0, level);
  },

  set_attacks: function(attacks) {
    this.attacks = attacks;

    var level = 0;
    if (attacks == this.def.attack_phases) level = 2;
    else if (attacks > 0) level = 1;

    this.attacks_indicator.set_sprite(0, level);
  },

  set_transport_capacity: function() {
    var capacity = 0;

    for (var i in this.loaded_units) {
      capacity += this.def.transport_armor_types[this.loaded_units[i].def.armor_type];
    }

    this.transport_indicator.set_sprite(0, capacity);
  },

  set_build_phase: function(phase) {
    this.build_phase = phase;

    if (this.build_phase != null && this.build_phase != undefined && this.build_phase > -1) {
      this.building_indicator.e.show();
    } else {
      this.building_indicator.e.hide();
    }
  },

  scrap_value: function() {
    var base = this.def.credits / 2;
    return Math.floor(base * 0.1 * this.health);
  },

  base_attack_vs_unit: function(unit) {
    var a = this.def.attack[unit.def.armor_type];
    if (a < 0) return 0;
    else return a;
  },

  attack_bonus_from_terrain: function(terrain) {
    return this.def.attack_bonus[terrain];
  },

  base_armor: function() {
    return this.def.armor;
  },

  armor_bonus_from_terrain: function(terrain) {
    return this.def.armor_bonus[terrain];
  },

  attack_vs_unit_from_terrain: function(unit, terrain) {
    var a = this.base_attack_vs_unit(unit);

    if (a > 0) {
      a = a + this.attack_bonus_from_terrain(terrain);
    }

    if (a < 0) return 0;
    else return a;
  },

  armor_from_terrain: function(terrain) {
    return this.base_armor() + this.armor_bonus_from_terrain(terrain);
  },

  base_combat_display: function(defender) {
    return this.base_attack_vs_unit(defender) + '/' + this.base_armor();
  },

  terrain_bonuses_display: function(terrain) {
    var a = this.attack_bonus_from_terrain(terrain);
    var d = this.armor_bonus_from_terrain(terrain);

    return (a >= 0 ? '+' + a : a) + '/' + (d >= 0 ? '+' + d : d);
  },

  flank_penalty_display: function() {
    return '0/-' + this.flank_penalty;
  },

  capture_penalty_display: function() {
    return '0/-2';
  },

  total_combat_display: function(defender, terrain, capturing) {
    var a = this.attack_vs_unit_from_terrain(defender, terrain);
    var d = this.armor_from_terrain(terrain) - this.flank_penalty;

    if (capturing) d -= 2;
    if (d < 0) d = 0;

    return a + '/' + d;
  },

  hit_chance_display: function(defender, terrain, defender_terrain, defender_capturing) {
    var a = this.attack_vs_unit_from_terrain(defender, terrain);
    var d = defender.armor_from_terrain(defender_terrain) - defender.flank_penalty;

    if (defender_capturing) d -= 2;
    if (d < 0) d = 0;

    var base = 0.5;

    var chance = Math.round((base + ((a - d) * 0.05)) * 100);
    if (chance < 0) chance = 0;

    return chance + '%';
  },

  can_attack_unit_type: function(defender_type) {
    return this.def.attack[GameConfig.units[defender_type].armor_type] > 0;
  },

  melee_attack: function() {
    return this.def.range[0] == 1;
  },

  can_zoc_unit_type: function(defender_type) {
    return this.melee_attack() && this.can_attack_unit_type(defender_type);
  },

  can_zoc: function(defender) {
    if (typeof this.def.zoc == 'object') {
      return $.inArray(defender.def.armor_type, this.def.zoc) > -1;
    } else if (this.def.zoc == 'normal') {
      return this.can_zoc_unit_type(defender.unit_type);
    } else {
      return false;
    }
  },

  can_load_unit: function(unit) {
    if (unit.player == this.player && this.def.transport_armor_types) {
      if (this.def.transport_armor_types[unit.def.armor_type]) {
        var capacity = 0;

        for (var i in this.loaded_units) {
          capacity += this.def.transport_armor_types[this.loaded_units[i].def.armor_type];
        }

        if (capacity + this.def.transport_armor_types[unit.def.armor_type] <= this.def.transport_capacity) {
          return true;
        }
      }
    }

    return false;
  },

  can_heal_unit: function(unit) {
    if (unit.player == this.player && this.def.can_heal) {
      if ($.inArray(unit.def.armor_type, this.def.can_heal) > -1) {
        if (unit.health < 10) {
          return true;
        }
      }
    }

    return false;
  },

  get_x: function() {
    return this.x;
  },

  get_y: function() {
    return this.y;
  },

  tile_index_cost: function(tile_index) {
    return this.def.movement[GameConfig.tiles[tile_index]];
  },

  terrain_cost: function(modified_terrain, actual_terrain) {
    if (modified_terrain && this.def.armor_type != 'naval') {
      return this.def.movement[modified_terrain];
    } else {
      return this.def.movement[actual_terrain];
    }
  },

  get_movement_points: function() {
    return this.movement_points;
  },

  max_movement_points: function() {
    return this.def.movement_points;
  },

  get_max_range: function() {
    return this.def.range[1];
  },

  get_min_range: function() {
    return this.def.range[0];
  },
});
