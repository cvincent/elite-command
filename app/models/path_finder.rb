class PathFinder
  def initialize(cost_map, walker, zoc_walkers)
    @cost_map = cost_map
    @walker = walker
    @zoc_walkers = zoc_walkers

    @found_tiles = {} # @found_tiles[[x, y]] = remaining_movement_points
    @found_tiles[[walker.x, walker.y]] = walker.movement_points

    initialize_zoc_tiles
  end

  def possible_destination_tiles
    starting_points = [[@walker.x, @walker.y]]

    loop do
      newly_found = []

      starting_points.each do |tile|
        possible_moves_from(tile, @found_tiles[tile]).each do |new_tile, rm_pts|
          old_rm_pts = @found_tiles[new_tile]

          if !old_rm_pts or old_rm_pts < rm_pts
            newly_found << new_tile
            @found_tiles[new_tile] = rm_pts
          end
        end
      end

      break if newly_found.empty?
      starting_points = newly_found
    end

    if @zoc_walkers
      @zoc_walkers.each do |zoc_walker|
        @found_tiles.delete([zoc_walker.x, zoc_walker.y])
      end
    end

    @found_tiles
  end

  def self.surrounding_tiles(x, y)
    ret = []

    (1..6).each do |direction|
      new_x = nil
      new_y = nil

      case direction
      when 1
        new_x = x - 1
        new_y = y
      when 2
        new_x = x - (y % 2 == 0 ? 1 : 0)
        new_y = y + 1
      when 3
        new_x = x + (y % 2 == 0 ? 0 : 1)
        new_y = y + 1
      when 4
        new_x = x + 1
        new_y = y
      when 5
        new_x = x + (y % 2 == 0 ? 0 : 1)
        new_y = y - 1
      when 6
        new_x = x - (y % 2 == 0 ? 1 : 0)
        new_y = y - 1
      end

      ret << [new_x, new_y]
    end

    ret
  end

  protected

  def initialize_zoc_tiles
    @zoc_tiles = []

    @zoc_walkers.each do |zoc_walker|
      if zoc_walker.can_zoc_unit_type?(@walker.unit_type)
        coord = [zoc_walker.x, zoc_walker.y]
        @zoc_tiles << coord

        self.each_tile_from(coord) do |zcoord|
          @zoc_tiles << zcoord
        end
      end
    end
  end

  def cost_at(x, y)
    if @cost_map[y]
      @cost_map[y][x]
    else
      nil
    end
  end

  def zoc_at?(x, y)
    @zoc_tiles.include?([x, y])
  end

  def possible_moves_from(coord, points)
    ret = {}

    self.each_tile_from(coord) do |new_coord|
      cost = @cost_map[new_coord]

      if cost and cost <= @walker.max_movement_points
        if @zoc_tiles.include?(coord) and @zoc_tiles.include?(new_coord)
          # Moving from one ZoC tile to another cost the walker's maximum movement points
          cost = @walker.max_movement_points
        end
      else
        cost = 99
      end

      ret[new_coord] = points - cost if points - cost >= 0
    end

    ret
  end

  def each_tile_from(coord, &block)
    x = coord[0]
    y = coord[1]

    PathFinder.surrounding_tiles(x, y).each do |coord|
      yield coord
    end
  end
end
