var SpriteSheets = {
  units: new SpriteSheet(
    '/images/game/units.png', 32, 34,
    'unit_facing', 'color',
    [
      'InfantryRight', 'InfantryLeft',
      'GrenadierRight', 'GrenadierLeft',
      'MortarRight', 'MortarLeft',
      'ArtilleryRight', 'ArtilleryLeft',
      'HumveeRight', 'HumveeLeft',
      'TankRight', 'TankLeft',
      'HeavyTankRight', 'HeavyTankLeft',
      'FighterRight', 'FighterLeft',
      'BomberRight', 'BomberLeft',
      'GunshipRight', 'GunshipLeft',
      'RangerRight', 'RangerLeft',
      'MobileFlakRight', 'MobileFlakLeft',
      'FrigateRight', 'FrigateLeft',
      'DestroyerRight', 'DestroyerLeft',
      'CruiserRight', 'CruiserLeft',
      'SniperRight', 'SniperLeft',
      'TransportRight', 'TransportLeft',
      'HeavyArtilleryRight', 'HeavyArtilleryLeft',
      'MedicRight', 'MedicLeft',
      'EngineerRight', 'EngineerLeft'
    ],
    GameConfig.colors
  ),

  bases: new SpriteSheet(
    '/images/game/bases.png', 32, 34,
    'x', 'y',
    ['Base', 'Airfield', 'Seaport'],
    GameConfig.colors
  ),

  health: new SpriteSheet(
    '/images/game/health.png', 32, 34,
    'x', 'y', [], []
  ),

  movement: new SpriteSheet(
    '/images/game/movement_indicator.png', 32, 34,
    'x', 'y', [], []
  ),

  attacks: new SpriteSheet(
    '/images/game/attack_indicator.png', 32, 34,
    'x', 'y', [], []
  ),

  transport_capacity: new SpriteSheet(
    '/images/game/transport_indicator.png', 32, 34,
    'x', 'y', [], []
  ),

  selection: new SpriteSheet(
    '/images/game/selection.png', 32, 34,
    'x', 'y', [], []
  ),

  target: new SpriteSheet(
    '/images/game/target.png', 32, 34,
    'x', 'y', [], []
  ),

  friendly_target: new SpriteSheet(
    '/images/game/friendly_target.png', 32, 34,
    'x', 'y', [], []
  ),

  base_capturing: new SpriteSheet(
    '/images/game/capturing.gif', 32, 34,
    'x', 'y', [], []
  ),

  unit_building: new SpriteSheet(
    '/images/game/building.gif', 32, 34,
    'x', 'y', [], []
  ),

  roads: new SpriteSheet(
    '/images/game/roads.png', 32, 34,
    'road', 'connections',
    ['road'],
    [
      '000000',
      '000001',
      '000010',
      '000011',
      '000100',
      '000101',
      '000110',
      '000111',
      '001000',
      '001001',
      '001010',
      '001011',
      '001100',
      '001101',
      '001110',
      '001111',
      '010000',
      '010001',
      '010010',
      '010011',
      '010100',
      '010101',
      '010110',
      '010111',
      '011000',
      '011001',
      '011010',
      '011011',
      '011100',
      '011101',
      '011110',
      '011111',
      '100000',
      '100001',
      '100010',
      '100011',
      '100100',
      '100101',
      '100110',
      '100111',
      '101000',
      '101001',
      '101010',
      '101011',
      '101100',
      '101101',
      '101110',
      '101111',
      '110000',
      '110001',
      '110010',
      '110011',
      '110100',
      '110101',
      '110110',
      '110111',
      '111000',
      '111001',
      '111010',
      '111011',
      '111100',
      '111101',
      '111110',
      '111111'
    ]
  ),

  bridges: new SpriteSheet(
    '/images/game/bridges.png', 32, 34,
    'bridge', 'connections',
    ['bridge'],
    [
      '110110',
      '010010',
      '011011',
      '001001',
      '101101',
      '100100'
    ]
  ),

  terrains: new SpriteSheet(
    '/images/game/tileset.png', 32, 34,
    'terrain', 'terrain',
    ['terrain'],
    [
      'plains',
      'sea',
      'mountains',
      'woods',
      'desert',
      'tundra',
      'swamp',
      'shallow_water',
      'ford',
      'void'
    ]
  )
};
