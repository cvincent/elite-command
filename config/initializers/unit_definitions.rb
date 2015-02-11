UnitDefinitions = {}

UnitDefinitions[:Infantry] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 6,
    woods: 4,
    desert: 4,
    tundra: 4,
    swamp: 6,
    shallow_water: 99,
    ford: 5,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 75,
  range: [1, 1],
  armor_type: :personnel,
  armor: 6,
  attack: {
    personnel: 6,
    armored: 3,
    air: 0,
    naval: 4
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 3,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: 0,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 2,
    woods: 2,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 2,
    airfield: 0,
    road: 0,
    bridge: 1
  },
  zoc: :normal
}

UnitDefinitions[:Grenadier] = {
  movement: {
    plains: 4,
    sea: 99,
    mountains: 9,
    woods: 4,
    desert: 5,
    tundra: 5,
    swamp: 9,
    shallow_water: 99,
    ford: 9,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 150,
  range: [1, 2],
  armor_type: :personnel,
  armor: 8,
  attack: {
    personnel: 8,
    armored: 9,
    air: 3,
    naval: 6
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 3,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: 0,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 2,
    woods: -1,
    desert: 0,
    tundra: 0,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: -1,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: [:personnel, :armored, :naval]
}

UnitDefinitions[:Mortar] = {
  movement: {
    plains: 4,
    sea: 99,
    mountains: 9,
    woods: 4,
    desert: 5,
    tundra: 5,
    swamp: 9,
    shallow_water: 99,
    ford: 9,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 200,
  range: [2, 3],
  armor_type: :personnel,
  armor: 6,
  attack: {
    personnel: 10,
    armored: 10,
    air: 0,
    naval: 10
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 3,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: 0,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 3,
    woods: -2,
    desert: 0,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -2,
    seaport: 0,
    base: -2,
    airfield: 0,
    road: 0,
    bridge: -1
  },
  zoc: false
}

UnitDefinitions[:Artillery] = {
  movement: {
    plains: 4,
    sea: 99,
    mountains: 99,
    woods: 6,
    desert: 5,
    tundra: 5,
    swamp: 6,
    shallow_water: 99,
    ford: 6,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 8,
  attack_phases: 1,
  attack_type: :exclusive,
  can_capture: false,
  credits: 400,
  range: [3, 4],
  armor_type: :armored,
  armor: 6,
  attack: {
    personnel: 12,
    armored: 13,
    air: 0,
    naval: 14
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -3,
    desert: 0,
    tundra: 0,
    swamp: -3,
    shallow_water: 0,
    ford: -2,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -3,
    desert: 0,
    tundra: 0,
    swamp: -3,
    shallow_water: -2,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: -2
  },
  zoc: false
}

UnitDefinitions[:Humvee] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 99,
    woods: 6,
    desert: 3,
    tundra: 6,
    swamp: 12,
    shallow_water: 99,
    ford: 12,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 15,
  attack_phases: 2,
  attack_type: :free,
  can_capture: false,
  credits: 300,
  range: [1, 1],
  armor_type: :armored,
  armor: 8,
  attack: {
    personnel: 9,
    armored: 3,
    air: 0,
    naval: 6
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -2,
    desert: 0,
    tundra: 0,
    swamp: -3,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 2,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -2,
    desert: 0,
    tundra: 0,
    swamp: -3,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 2,
    bridge: 0
  },
  zoc: :normal
}

UnitDefinitions[:Tank] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 99,
    woods: 6,
    desert: 4,
    tundra: 5,
    swamp: 8,
    shallow_water: 99,
    ford: 8,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 12,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: false,
  credits: 350,
  range: [1, 1],
  armor_type: :armored,
  armor: 12,
  attack: {
    personnel: 10,
    armored: 10,
    air: 0,
    naval: 9
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -3,
    desert: 0,
    tundra: 0,
    swamp: -4,
    shallow_water: -2,
    ford: 0,
    seaport: 0,
    base: -2,
    airfield: 0,
    road: 1,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 1,
    bridge: 0
  },
  zoc: :normal
}

UnitDefinitions[:HeavyTank] = {
  movement: {
    plains: 4,
    sea: 99,
    mountains: 99,
    woods: 6,
    desert: 5,
    tundra: 7,
    swamp: 8,
    shallow_water: 99,
    ford: 8,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 12,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: false,
  credits: 500,
  range: [1, 1],
  armor_type: :armored,
  armor: 15,
  attack: {
    personnel: 15,
    armored: 12,
    air: 0,
    naval: 12
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -3,
    desert: 0,
    tundra: 0,
    swamp: -4,
    shallow_water: 0,
    ford: -2,
    seaport: 0,
    base: -2,
    airfield: 0,
    road: 1,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 1,
    bridge: 0
  },
  zoc: :normal
}

UnitDefinitions[:Fighter] = {
  movement: {
    plains: 3,
    sea: 3,
    mountains: 3,
    woods: 3,
    desert: 3,
    tundra: 3,
    swamp: 3,
    shallow_water: 3,
    ford: 3,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 24,
  attack_phases: 1,
  attack_type: :free,
  can_capture: false,
  credits: 450,
  range: [1, 1],
  armor_type: :air,
  armor: 12,
  attack: {
    personnel: 4,
    armored: 6,
    air: 16,
    naval: 8
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: false
}

UnitDefinitions[:Bomber] = {
  movement: {
    plains: 3,
    sea: 3,
    mountains: 3,
    woods: 3,
    desert: 3,
    tundra: 3,
    swamp: 3,
    shallow_water: 3,
    ford: 3,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 24,
  attack_phases: 1,
  attack_type: :free,
  can_capture: false,
  credits: 650,
  range: [1, 1],
  armor_type: :air,
  armor: 10,
  attack: {
    personnel: 14,
    armored: 16,
    air: 4,
    naval: 15
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: false
}

UnitDefinitions[:Gunship] = {
  movement: {
    plains: 3,
    sea: 3,
    mountains: 3,
    woods: 3,
    desert: 3,
    tundra: 3,
    swamp: 3,
    shallow_water: 3,
    ford: 3,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 15,
  attack_phases: 1,
  attack_type: :free,
  can_capture: false,
  credits: 350,
  range: [1, 1],
  armor_type: :air,
  armor: 8,
  attack: {
    personnel: 18,
    armored: 10,
    air: 8,
    naval: 9
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: [:personnel, :armored, :naval]
}

UnitDefinitions[:Ranger] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 6,
    woods: 3,
    desert: 3,
    tundra: 3,
    swamp: 3,
    shallow_water: 6,
    ford: 3,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 200,
  range: [1, 1],
  armor_type: :personnel,
  armor: 9,
  attack: {
    personnel: 9,
    armored: 4,
    air: 0,
    naval: 6
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 4,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: -2,
    ford: 0,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: 0,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 2,
    woods: 2,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: -2,
    ford: 0,
    seaport: 0,
    base: 2,
    airfield: 0,
    road: 0,
    bridge: 1
  },
  zoc: :normal,
  notes: [
    'Not slowed by woods, desert, tundra, swamp, or fords',
    'Able to move through shallow water'
  ]
}

UnitDefinitions[:MobileFlak] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 99,
    woods: 6,
    desert: 6,
    tundra: 6,
    swamp: 6,
    shallow_water: 99,
    ford: 6,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 9,
  attack_phases: 2,
  attack_type: :move_attack,
  can_capture: false,
  credits: 350,
  range: [1, 3],
  armor_type: :armored,
  armor: 8,
  attack: {
    personnel: 0,
    armored: 0,
    air: 14,
    naval: 0
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -2,
    desert: 0,
    tundra: -1,
    swamp: -3,
    shallow_water: 0,
    ford: -2,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 2,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -3,
    desert: 0,
    tundra: 0,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: [:air]
}

UnitDefinitions[:Frigate] = {
  movement: {
    plains: 99,
    sea: 1,
    mountains: 99,
    woods: 99,
    desert: 99,
    tundra: 99,
    swamp: 99,
    shallow_water: 1,
    ford: 99,
    seaport: 1,
    base: 99,
    airfield: 99,
    road: 99,
    bridge: 99,
    void: 99
  },
  movement_points: 8,
  attack_phases: 2,
  attack_type: :free,
  can_capture: false,
  credits: 300,
  range: [1, 1],
  armor_type: :naval,
  armor: 8,
  attack: {
    personnel: 9,
    armored: 9,
    air: 0,
    naval: 8
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: :normal
}

UnitDefinitions[:Destroyer] = {
  movement: {
    plains: 99,
    sea: 1,
    mountains: 99,
    woods: 99,
    desert: 99,
    tundra: 99,
    swamp: 99,
    shallow_water: 99,
    ford: 99,
    seaport: 1,
    base: 99,
    airfield: 99,
    road: 99,
    bridge: 99,
    void: 99
  },
  movement_points: 5,
  attack_phases: 1,
  attack_type: :free,
  can_capture: false,
  credits: 600,
  range: [1, 4],
  armor_type: :naval,
  armor: 12,
  attack: {
    personnel: 10,
    armored: 12,
    air: 0,
    naval: 8
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: :normal
}

UnitDefinitions[:Cruiser] = {
  movement: {
    plains: 99,
    sea: 1,
    mountains: 99,
    woods: 99,
    desert: 99,
    tundra: 99,
    swamp: 99,
    shallow_water: 99,
    ford: 99,
    seaport: 1,
    base: 99,
    airfield: 99,
    road: 99,
    bridge: 99,
    void: 99
  },
  movement_points: 4,
  attack_phases: 2,
  attack_type: :move_attack,
  can_capture: false,
  credits: 1000,
  range: [1, 3],
  armor_type: :naval,
  armor: 15,
  attack: {
    personnel: 14,
    armored: 16,
    air: 14,
    naval: 12
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  zoc: :normal
}

UnitDefinitions[:Sniper] = {
  movement: {
    plains: 4,
    sea: 99,
    mountains: 9,
    woods: 4,
    desert: 5,
    tundra: 5,
    swamp: 9,
    shallow_water: 99,
    ford: 9,
    seaport: 3,
    base: 3,
    airfield: 3,
    road: 3,
    bridge: 3,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 275,
  range: [2, 4],
  armor_type: :personnel,
  armor: 5,
  attack: {
    personnel: 8,
    armored: 0,
    air: 0,
    naval: 0
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 3,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: -2,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 4,
    woods: -4,
    desert: -1,
    tundra: -1,
    swamp: -3,
    shallow_water: 0,
    ford: -6,
    seaport: 0,
    base: 2,
    airfield: 0,
    road: 0,
    bridge: -1
  },
  zoc: false
}

UnitDefinitions[:Transport] = {
  movement: {
    plains: 99,
    sea: 1,
    mountains: 99,
    woods: 99,
    desert: 99,
    tundra: 99,
    swamp: 99,
    shallow_water: 1,
    ford: 99,
    seaport: 1,
    base: 99,
    airfield: 99,
    road: 99,
    bridge: 99,
    void: 99
  },
  movement_points: 8,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: false,
  credits: 450,
  range: [1, 1],
  armor_type: :naval,
  armor: 8,
  attack: {
    personnel: 3,
    armored: 3,
    air: 0,
    naval: 3
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: 0,
    desert: 0,
    tundra: 0,
    swamp: 0,
    shallow_water: 0,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  transport_armor_types: {
    :personnel => 1,
    :armored => 3
  },
  transport_capacity: 6, # Up to 6 personnel or 3 armored units
  zoc: false,
  notes: ['Can load and transport up to 6 personnel units, 2 armored units, or 1 armored unit + 3 personnel units.']
}

UnitDefinitions[:HeavyArtillery] = {
  movement: {
    plains: 2,
    sea: 99,
    mountains: 99,
    woods: 2,
    desert: 2,
    tundra: 2,
    swamp: 2,
    shallow_water: 99,
    ford: 2,
    seaport: 1,
    base: 1,
    airfield: 1,
    road: 1,
    bridge: 1,
    void: 99
  },
  movement_points: 2,
  attack_phases: 1,
  attack_type: :exclusive,
  can_capture: false,
  credits: 1250,
  range: [4, 6],
  armor_type: :armored,
  armor: 8,
  attack: {
    personnel: 14,
    armored: 15,
    air: 0,
    naval: 15
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -3,
    desert: 0,
    tundra: 0,
    swamp: -3,
    shallow_water: 0,
    ford: -2,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: 0
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 0,
    woods: -5,
    desert: 0,
    tundra: 0,
    swamp: -5,
    shallow_water: -4,
    ford: 0,
    seaport: 0,
    base: 0,
    airfield: 0,
    road: 0,
    bridge: -2
  },
  zoc: false
}

UnitDefinitions[:Medic] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 6,
    woods: 4,
    desert: 4,
    tundra: 4,
    swamp: 6,
    shallow_water: 99,
    ford: 5,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 100,
  range: [1, 1],
  armor_type: :personnel,
  armor: 6,
  attack: {
    personnel: 5,
    armored: 2,
    air: 0,
    naval: 3
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 3,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: 0,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 2,
    woods: 2,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: 0,
    ford: -1,
    seaport: 0,
    base: 2,
    airfield: 0,
    road: 0,
    bridge: 1
  },
  zoc: :normal,
  can_heal: [:personnel]
}

UnitDefinitions[:Engineer] = {
  movement: {
    plains: 3,
    sea: 99,
    mountains: 6,
    woods: 4,
    desert: 4,
    tundra: 4,
    swamp: 6,
    shallow_water: 7,
    ford: 5,
    seaport: 2,
    base: 2,
    airfield: 2,
    road: 2,
    bridge: 2,
    void: 99
  },
  movement_points: 9,
  attack_phases: 1,
  attack_type: :move_attack,
  can_capture: true,
  credits: 200,
  range: [1, 1],
  armor_type: :personnel,
  armor: 6,
  attack: {
    personnel: 5,
    armored: 2,
    air: 0,
    naval: 3
  },
  armor_bonus: {
    plains: 0,
    sea: 0,
    mountains: 5,
    woods: 3,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: -2,
    ford: -1,
    seaport: 0,
    base: 3,
    airfield: 0,
    road: 0,
    bridge: 2
  },
  attack_bonus: {
    plains: 0,
    sea: 0,
    mountains: 2,
    woods: 2,
    desert: -1,
    tundra: -1,
    swamp: -2,
    shallow_water: -2,
    ford: -1,
    seaport: 0,
    base: 2,
    airfield: 0,
    road: 0,
    bridge: 1
  },
  zoc: :normal,
  can_heal: [:armored],
  can_build: {
    plains: { credits: 25, turns: 1 },
    road: { credits: 50, turns: 1 },
    bridge: { credits: 100, turns: 1 },
    destroy: { credits: 0, turns: 1 }
  },
  notes: [
    'Able to move through shallow water'
  ]
}



UnitDefinitions.each do |type, data|
  UnitDefinitions[type][:human_name] = type.to_s.underscore.humanize
end



BaseDefinitions = {}

BaseDefinitions[:Base] = {
  can_build: [
    :Infantry,
    :Medic,
    :Grenadier,
    :Engineer,
    :Ranger,
    :Mortar,
    :Sniper,
    :MobileFlak,
    :Artillery,
    :Humvee,
    :Tank,
    :HeavyTank,
    :HeavyArtillery
  ].sort_by { |ut| UnitDefinitions[ut][:credits] }
}

BaseDefinitions[:Airfield] = {
  can_build: [
    :MobileFlak,
    :Gunship,
    :Fighter,
    :Bomber
  ].sort_by { |ut| UnitDefinitions[ut][:credits] }
}

BaseDefinitions[:Seaport] = {
  can_build: [
    :Frigate,
    :Destroyer,
    :Cruiser,
    :Transport
  ].sort_by { |ut| UnitDefinitions[ut][:credits] }
}



TerrainModifierDefinitions = {}

TerrainModifierDefinitions[:road] = {
  allowed_on: [
    :plains, :desert, :tundra
  ],
  terrain_name: :road
}

TerrainModifierDefinitions[:bridge] = {
  allowed_on: [
    :shallow_water, :ford
  ],
  terrain_name: :bridge
}



FreeUnitTypes = [
  :Infantry,
  :Grenadier,
  :Ranger,
  :Mortar,
  :Humvee,
  :Tank
]



PlayerColors = [
  :Grey,
  :Red,
  :Blue,
  :Green,
  :Orange,
  :Pink,
  :Yellow
]



TileTypes = [
  :plains,
  :sea,
  :mountains,
  :woods,
  :desert,
  :tundra,
  :swamp,
  :shallow_water,
  :ford,
  :void,
  :seaport,
  :base,
  :airfield,
  :road,
  :bridge
]
