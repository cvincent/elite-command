class MapRenderer
  TileSize = 32
  TileSizeH = 8
  TileSizeS = 18
  TileSizeR = 16
  
  TilesetFile = File.join(Rails.root, 'public', 'images', 'game', 'tileset.png')
  BaseTilesetFile = File.join(Rails.root, 'public', 'images', 'game', 'bases.png')
  UnitTilesetFile = File.join(Rails.root, 'public', 'images', 'game', 'units.png')
  
  def initialize(map_data = [], bases = [], units = [])
    @map_data = map_data
    @bases = bases
    @units = units
  end
  
  def set_data(map_data, bases, units)
    @map_data = map_data
    @bases = bases
    @units = units
  end
  
  def tile_width
    @map_data[0].size
  end
  
  def tile_height
    @map_data.size
  end
  
  def render(filename, thumbnail)
    pixel_width = tile_width * TileSize + TileSizeR
    pixel_height = tile_height * (TileSizeS + TileSizeH) + TileSizeH
    
    canvas = Magick::Image.new(pixel_width, pixel_height)
    d = Magick::Draw.new
    
    d.fill('black')
    d.rectangle(0, 0, pixel_width - 1, pixel_height - 1)
    
    @map_data.each_with_index do |row, y|
      row.each_with_index do |t, x|
        px, py = tile_to_pixel_coords(x, y)
        d.composite(px, py, 0, 0, tile_graphic(t))
      end
    end
    
    @bases.each do |base|
      px, py = tile_to_pixel_coords(base['x'], base['y'])
      d.composite(px, py, 0, 0, base_graphic(base['base_type'], base['player']))
    end
    
    @units.each do |unit|
      px, py = tile_to_pixel_coords(unit['x'], unit['y'])
      d.composite(px, py, 0, 0, unit_graphic(unit['unit_type'], unit['player']))
    end
    
    d.draw(canvas)
    
    canvas.write(filename)
    
    if canvas.columns > 431
      canvas.scale(430, canvas.rows * (430.0 / canvas.columns)).write(thumbnail)
    else
      canvas.write(thumbnail)
    end
  end
  
  
  
  protected
  
  def tileset
    @tileset ||= Magick::Image.read(TilesetFile)[0]
  end
  
  def tile_graphic(index)
    index = index.to_i
    @tile_graphics ||= {}
    @tile_graphics[index] ||= tileset.crop(index * TileSize, 0, TileSize, TileSizeS + (TileSizeH * 2))
  end
  
  def base_tileset
    @base_tileset ||= Magick::Image.read(BaseTilesetFile)[0]
  end
  
  def base_graphic(base_type, player_index)
    @base_graphics ||= {}
    @base_graphics[base_type.to_sym] = base_tileset.crop(
      BaseDefinitions.keys.index(base_type.to_sym) * TileSize,
      player_index * (TileSizeS + (TileSizeH * 2)),
      TileSize, TileSizeS + (TileSizeH * 2)
    )
  end
  
  def unit_tileset
    @unit_tileset ||= Magick::Image.read(UnitTilesetFile)[0]
  end
  
  def unit_graphic(unit_type, player_index)
    @unit_graphics ||= {}
    @unit_graphics[unit_type.to_sym] = unit_tileset.crop(
      UnitDefinitions.keys.index(unit_type.to_sym) * TileSize * 2,
      player_index * (TileSizeS + (TileSizeH * 2)),
      TileSize, TileSizeS + (TileSizeH * 2)
    )
  end
  
  def tile_to_pixel_coords(tx, ty)
    px = 0
    py = ty * (TileSizeH + TileSizeS)
    
    if ty % 2 == 0
      px = tx * 2 * TileSizeR
    else
      px = tx * 2 * TileSizeR + TileSizeR
    end
    
    return px, py
  end
end
