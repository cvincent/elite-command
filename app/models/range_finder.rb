class RangeFinder < PathFinder
  def initialize(cost_map, walker)
    @cost_map = cost_map
    @walker = walker

    @min = UnitDefinitions[@walker.unit_type][:range][0]
    @max = UnitDefinitions[@walker.unit_type][:range][1]

    @found_tiles = {} # @found_tiles[[x, y]] = remaining_movement_points
    @found_tiles[[@walker.x, @walker.y]] = @max

    initialize_zoc_tiles
  end

  def possible_destination_tiles
    super.delete_if do |k, v|
      @max - v < @min
    end
  end

  protected

  def initialize_zoc_tiles
    @zoc_tiles = []
  end
end
