class Unit
  attr_accessor :unit_type, :player, :x, :y,
    :health, :movement_points,
    :attacks, :attacked, :healed, :flank_penalty, :loaded_units,
    :player_id, :summoning_sickness, :moved,
    :build_phase, :current_build

  def initialize(
    unit_type, player, x, y,
    health = 10, movement_points = nil,
    attacks = 0, flank_penalty = 0, loaded_units = [], summoning_sickness = true,
    moved = true, build_phase = nil, current_build = nil, attacked = false,
    healed = false
  )
    @unit_type = unit_type
    @player = player
    @x = x
    @y = y
    @health = health
    @movement_points = movement_points || UnitDefinitions[unit_type][:movement_points]
    @attacks = attacks
    @attacked = attacked
    @healed = healed
    @flank_penalty = flank_penalty
    @loaded_units = loaded_units
    @player_id = nil
    @summoning_sickness = summoning_sickness
    @moved = moved
    @build_phase = build_phase
    @current_build = current_build
  end

  def self.price_for_unit_type(unit_type)
    UnitDefinitions[unit_type][:credits] rescue nil
  end

  def scrap_value
    base = Unit.price_for_unit_type(self.unit_type).to_f / 2.0
    (base * 0.1 * self.health).to_i
  end

  def can_attack_unit_type?(defender_type)
    (self.attack[UnitDefinitions[defender_type][:armor_type]] || 0) > 0
  end

  def has_enough_attack_points_to_attack?
    attacks < attack_phases
  end

  def attack_allowed_by_attack_type?
    attack_type != :exclusive or moved == false
  end

  def calculate_damage(terrain, defender, defender_terrain, defender_capturing = false)
    a = attack[defender.armor_type] + attack_bonus[terrain]
    a = 0 if a < 0 or attack[defender.armor_type] == 0

    d = defender.armor + defender.armor_bonus[defender_terrain]
    d -= 2 if defender_capturing
    d = 0 if d < 0 or defender.armor == 0

    p = 0.05 * (a - d + defender.flank_penalty) + 0.5

    damage = 0
    health.times { damage += 1 if rand < p }

    damage
  end

  def melee_attack?
    self.range[0] == 1
  end

  def can_zoc_unit_type?(defender_type)
    if self.zoc.is_a?(Array)
      self.zoc.include?(UnitDefinitions[defender_type][:armor_type])
    elsif self.zoc
      self.melee_attack? and self.can_attack_unit_type?(defender_type)
    else
      false
    end
  end

  def can_capture?
    self.can_capture
  end

  def loaded_capacity
    self.loaded_units.map do |u|
      self.transport_armor_types[u.armor_type]
    end.sum
  end

  def can_heal_unit_type?(unit_type)
    self.can_heal and self.can_heal.include?(UnitDefinitions[unit_type][:armor_type])
  end

  def copy_attributes_to_unit(unit)
    self.instance_variables.each do |v|
      unit.instance_variable_set(v, self.instance_variable_get(v))
    end
  end

  def tile_index_cost(tile_index)
    UnitDefinitions[@unit_type][:movement][TileTypes[tile_index]]
  end

  def terrain_cost(modified_terrain, actual_terrain)
    if modified_terrain and self.armor_type != :naval
      UnitDefinitions[@unit_type][:movement][modified_terrain]
    else
      UnitDefinitions[@unit_type][:movement][actual_terrain]
    end
  end

  def max_movement_points
    UnitDefinitions[@unit_type][:movement_points]
  end

  def to_json_hash
    h = {}
    self.instance_variables.each do |v|
      h[v.to_s[1..-1].to_sym] = self.instance_variable_get(v)
    end
    h
  end

  def self.from_json_hash(json)
    u = Unit.allocate
    json.each do |k, v|
      u.instance_variable_set(:"@#{k}", v)
    end
    u
  end

  protected

  def method_missing(meth, *args)
    if UnitDefinitions[@unit_type].has_key?(meth)
      UnitDefinitions[@unit_type][meth]
    else
      super
    end
  end

  def respond_to_missing?(meth, *args)
    UnitDefinitions[@unit_type].has_key?(meth)
  end
end
