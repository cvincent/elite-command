class TerrainModifier
  attr_accessor :terrain_name, :x, :y

  def initialize(terrain_name, x, y)
    @terrain_name, @x, @y = terrain_name, x, y
  end

  def to_json_hash
    {
      terrain_name: @terrain_name,
      x: @x, y: @y
    }
  end

  def from_json_hash(json)
    tm = TerrainModifier.allocate
    json.each do |k, v|
      tm.instance_variable_set(:"@#{k}", v)
    end
    tm
  end
end
