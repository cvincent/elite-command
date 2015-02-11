Fabricator(:map) do
  name { Fabricate.sequence(:name) { |i| "Map #{i}" } }
  starting_credits 0
  status 'published'
end

Fabricator(:basic_1v1_map, :from => :map) do
  tiles [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
  ]
  bases [
    {"player"=>1, "base_type"=>"Base", "x"=>8, "y"=>3, "capturing"=>false},
    {"player"=>2, "base_type"=>"Base", "x"=>11, "y"=>5, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>11, "y"=>9, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>8, "y"=>11, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>5, "y"=>9, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>5, "y"=>5, "capturing"=>false}
  ]
  units [
    {"player"=>1, "unit_type"=>"Infantry", "x"=>8, "y"=>4},
    {"player"=>2, "unit_type"=>"Infantry", "x"=>10, "y"=>5}
  ]
end

Fabricator(:basic_1v1v1_map, :from => :map) do
  tiles [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 0, 2, 0, 2, 10, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 7, 7, 3, 5, 0, 10, 8, 6, 7, 7, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 7, 0, 0, 0, 0, 0, 0, 0, 7, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 6, 0, 0, 4, 4, 0, 0, 3, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 10, 8, 0, 4, 2, 4, 0, 5, 0, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 2, 10, 0, 4, 4, 0, 0, 2, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 10, 0, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 2, 5, 0, 0, 8, 2, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 0, 3, 0, 6, 10, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
  ]
  bases [
    {"player"=>1, "base_type"=>"Base", "x"=>9, "y"=>7, "capturing"=>false},
    {"player"=>2, "base_type"=>"Base", "x"=>11, "y"=>10, "capturing"=>false},
    {"player"=>3, "base_type"=>"Base", "x"=>8, "y"=>10, "capturing"=>false},
    {"player"=>2, "base_type"=>"Airfield", "x"=>12, "y"=>10, "capturing"=>false},
    {"player"=>2, "base_type"=>"Seaport", "x"=>11, "y"=>11, "capturing"=>false},
    {"player"=>3, "base_type"=>"Airfield", "x"=>7, "y"=>11, "capturing"=>false},
    {"player"=>3, "base_type"=>"Seaport", "x"=>7, "y"=>10, "capturing"=>false},
    {"player"=>1, "base_type"=>"Base", "x"=>6, "y"=>7, "capturing"=>false},
    {"player"=>1, "base_type"=>"Base", "x"=>12, "y"=>7, "capturing"=>false},
    {"player"=>2, "base_type"=>"Base", "x"=>9, "y"=>13, "capturing"=>false},
    {"player"=>1, "base_type"=>"Seaport", "x"=>10, "y"=>6, "capturing"=>false},
    {"player"=>1, "base_type"=>"Airfield", "x"=>9, "y"=>6, "capturing"=>false},
    {"player"=>0, "base_type"=>"Airfield", "x"=>7, "y"=>5, "capturing"=>false},
    {"player"=>0, "base_type"=>"Airfield", "x"=>13, "y"=>9, "capturing"=>false},
    {"player"=>0, "base_type"=>"Airfield", "x"=>7, "y"=>13, "capturing"=>false},
    {"player"=>0, "base_type"=>"Seaport", "x"=>11, "y"=>5, "capturing"=>false},
    {"player"=>0, "base_type"=>"Seaport", "x"=>11, "y"=>13, "capturing"=>false},
    {"player"=>0, "base_type"=>"Seaport", "x"=>5, "y"=>9, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>9, "y"=>5, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>12, "y"=>11, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>6, "y"=>11, "capturing"=>false}
  ]
  units [
    {"player"=>1, "unit_type"=>"Infantry", "x"=>10, "y"=>7},
    {"player"=>2, "unit_type"=>"Infantry", "x"=>10, "y"=>11},
    {"player"=>3, "unit_type"=>"Infantry", "x"=>7, "y"=>9}
  ]
end

Fabricator(:buildings_spec_map, from: :map) do
  tiles [[0, 0, 0, 0, 0, 0, 2, 2, 5, 5, 5, 5, 2, 2, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 0, 2, 2, 5, 5, 5, 2, 2, 0, 1, 1, 1, 1, 0, 9],
    [0, 0, 1, 0, 1, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 1, 0, 1, 0, 0],
    [0, 0, 1, 1, 0, 0, 12, 0, 3, 3, 3, 0, 12, 0, 0, 1, 1, 0, 0, 9],
    [0, 0, 0, 1, 0, 0, 0, 11, 0, 3, 3, 0, 11, 0, 0, 0, 1, 0, 0, 0],
    [0, 0, 0, 6, 7, 7, 2, 2, 0, 0, 0, 2, 2, 7, 7, 6, 0, 0, 0, 9],
    [7, 0, 0, 6, 7, 0, 7, 2, 0, 0, 0, 0, 2, 7, 0, 7, 6, 0, 0, 7],
    [7, 0, 0, 7, 0, 7, 3, 0, 0, 7, 0, 0, 3, 7, 0, 7, 0, 0, 7, 9],
    [1, 7, 0, 0, 7, 7, 3, 0, 0, 7, 7, 0, 0, 3, 7, 7, 0, 0, 7, 1],
    [1, 7, 0, 0, 0, 0, 0, 0, 7, 0, 7, 0, 0, 0, 0, 0, 0, 7, 1, 9],
    [1, 7, 0, 0, 11, 0, 0, 0, 7, 0, 0, 7, 0, 0, 0, 11, 0, 0, 7, 1],
    [1, 7, 0, 0, 0, 0, 0, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, 7, 1, 9],
    [1, 1, 7, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 7, 1, 1],
    [1, 7, 0, 3, 3, 3, 0, 0, 4, 4, 4, 0, 0, 3, 3, 3, 0, 7, 1, 9],
    [1, 7, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 7, 1],
    [1, 7, 0, 0, 0, 0, 11, 0, 7, 7, 7, 0, 11, 0, 0, 0, 0, 7, 1, 9],
    [1, 1, 7, 7, 7, 7, 0, 0, 7, 7, 7, 7, 0, 0, 7, 7, 7, 7, 1, 1],
    [1, 1, 1, 1, 1, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 1, 1, 1, 9],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
  ]
  bases [{"player"=>1, "base_type"=>"Base", "x"=>4, "y"=>10, "capturing"=>false},
    {"player"=>2, "base_type"=>"Base", "x"=>15, "y"=>10, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>12, "y"=>15, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>6, "y"=>15, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>7, "y"=>4, "capturing"=>false},
    {"player"=>0, "base_type"=>"Base", "x"=>12, "y"=>4, "capturing"=>false},
    {"player"=>0, "base_type"=>"Airfield", "x"=>6, "y"=>3, "capturing"=>false},
    {"player"=>0, "base_type"=>"Airfield", "x"=>12, "y"=>3, "capturing"=>false}
  ]
  units [{"player"=>1, "unit_type"=>"Engineer", "x"=>8, "y"=>9},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>4, "y"=>6},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>9, "y"=>15},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>9, "y"=>16},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>14, "y"=>13},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>9, "y"=>13},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>9, "y"=>0},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>13, "y"=>12},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>11, "y"=>1},
    {"player"=>1, "unit_type"=>"Engineer", "x"=>2, "y"=>2}
  ]
end
