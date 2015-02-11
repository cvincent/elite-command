class Base
  attr_accessor :base_type, :player, :player_id, :x, :y, :capture_phase, :capture_player_id, :capture_player

  def initialize(base_type, player, x, y, capture_phase = nil, capture_player_id = nil)
    @base_type = base_type
    @player = player
    @player_id = nil
    @x = x
    @y = y
    @capture_phase = capture_phase
    @capture_player_id = capture_player_id
  end

  def unit_types
    BaseDefinitions[base_type][:can_build]
  end

  def can_build_unit_type?(unit_type)
    unit_types.include?(unit_type)
  end

  def build_unit_type(unit_type)
    u = Unit.new(unit_type, player, x, y, 10, 0, UnitDefinitions[unit_type][:attack_phases])
    u.player_id = player_id
    u
  end

  def start_capture(capture_player_id, capture_player)
    @capture_player_id = capture_player_id
    @capture_player = capture_player
    @capture_phase = 1
  end

  def continue_capture
    @capture_phase -= 1

    if @capture_phase < 0
      @player_id = @capture_player_id
      @player = @capture_player
      @capture_phase = nil
      @capture_player_id = nil
      @capture_player = nil
      true
    else
      false
    end
  end

  def cancel_capture
    @capture_phase = nil
    @capture_player_id = nil
    @capture_player = nil
  end

  def to_json_hash
    h = {}
    self.instance_variables.each do |v|
      h[v.to_s[1..-1].to_sym] = self.instance_variable_get(v)
    end
    h
  end
end
