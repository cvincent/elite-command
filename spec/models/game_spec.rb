require 'spec_helper'

describe Game do
  before do
    @testmap1 = Fabricate(:basic_1v1_map)
    @game = Game.create(:name => 'testgame', :map => @testmap1, :time_limit => 1.hour)

    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @user3 = Fabricate(:user)
  end

  describe 'serialization' do
    it 'should serialize units to a string when saving and deserialize to
        an array of Unit objects when initializing' do

      unit_array = [Unit.new(:Infantry, 0, 5, 5), Unit.new(:Infantry, 0, 6, 6)]

      g = Game.create(:name => 'test', :map => @testmap1)
      g.units = unit_array
      g.save

      g = Game.find(g._id)
      g.units.size.should == 2
      g.units[0].should be_a(Unit)

      g.units << Unit.new(:Tank, 0, 10, 10)
      g.save

      g = Game.find(g._id)
      g.units.size.should == 3
      g.units[2].should be_a(Unit)
    end

    it 'should serialize bases to a string when saving and deserialize to
        an array of Base objects when initializing' do

      base_array = [Base.new(:Base, 0, 5, 5), Base.new(:Base, 0, 6, 6)]

      g = Game.create(:name => 'test', :map => @testmap1)
      g.bases = base_array
      g.save

      g = Game.find(g._id)
      g.bases.size.should == 2
      g.bases[0].should be_a(Base)

      g.bases << Base.new(:Airfield, 0, 10, 10)
      g.save

      g = Game.find(g._id)
      g.bases.size.should == 3
      g.bases[2].should be_a(Base)
    end

    it "should serialize command_history to a string when saving and deserialize to
        an array of GameCommand objects when initializing" do

      g = Game.create(:name => 'test', :map => @testmap1)

      command_array = [
        MoveUnit.new(g, @user1, :unit_x => 1, :unit_y => 1, :unit_slot => nil, :dest_x => 2, :dest_y => 2),
        MoveUnit.new(g, @user1, :unit_x => 2, :unit_y => 2, :unit_slot => nil, :dest_x => 3, :dest_y => 3)
      ]

      g.command_history = command_array
      g.save

      g = Game.find(g._id)
      g.command_history.size.should == 2
      g.command_history[0].should be_a(MoveUnit)

      g.command_history << GameCommand.new(g, @user1)
      g.save

      g = Game.find(g._id)
      g.command_history.size.should == 3
      g.command_history[2].should be_a(GameCommand)
    end

    it 'should not serialize bases, units, or command history to nil if they are not accessed before saving' do
      unit_array = [Unit.new(:Infantry, 0, 5, 5), Unit.new(:Infantry, 0, 6, 6)]
      base_array = [Base.new(:Base, 0, 5, 5), Base.new(:Base, 0, 6, 6)]

      g = Game.create(:name => 'test', :map => @testmap1)

      command_array = [GameCommand.new(g, @user1)]

      g.units = unit_array
      g.bases = base_array
      g.command_history = command_array
      g.save

      g = Game.last
      g.save

      g = Game.last
      g.units.should_not be_nil
      g.bases.should_not be_nil
      g.command_history.should_not be_nil
    end
  end

  describe 'creation' do
    it 'should duplicate the units from the map' do
      g = @game

      g.units.size.should == 2
      g.units[0].unit_type.should == :Infantry
      g.units[0].x.should == 8
      g.units[0].y.should == 4
      g.units[1].unit_type.should == :Infantry
      g.units[1].x.should == 10
      g.units[1].y.should == 5
    end
    
    it 'should duplicate the bases from the map' do
      g = @game

      g.bases.size.should == 6
      g.bases[0].base_type.should == :Base
      g.bases[0].x.should == 8
      g.bases[0].y.should == 3

      g.bases[1].base_type.should == :Base
      g.bases[1].x.should == 11
      g.bases[1].y.should == 5
    end

    it 'should initialize the command history as an empty array' do
      g = @game
      g.command_history.should_not be_nil
      g.command_history.should be_empty
    end
  end

  describe '#add_player!(user)' do
    it 'should fail if the game is full' do
      @game.add_player!(@user1)
      @game.add_player!(@user2)
      @game.add_player!(@user3).should == false
    end

    it 'should fail if the player is already in the game' do
      @game.add_player!(@user1)
      @game.add_player!(@user1).should == false
    end

    it "should add a valid user to the #users array and the user's #_id to the #players array" do
      @game.add_player!(@user1)
      @game.users.should include(@user1)
      @game.players.should include(@user1._id)
      @game.add_player!(@user2)
      @game.users.should include(@user2)
      @game.players.should include(@user2._id)
    end

    it "should set Game#game_type if the user is the first user" do
      @game.add_player!(Fabricate(:user, :account_type => 'free'))
      @game.add_player!(@user1)
      @game.game_type.should == 'free'
    end

    it "should set #turn_started_at to Time.now if it is the new player's turn" do
      now = Time.now
      Time.stub(:now => now)
      @game.add_player!(@user1)
      @game.turn_started_at.to_time.to_i.should == now.to_time.to_i
    end

    it "should set the new player's units and bases #player_id to the new player's #_id" do
      @game.add_player!(@user1)
      Game.find(@game._id).unit_at(8, 4).player_id.should == @user1._id.to_s
      Game.find(@game._id).base_at(8, 3).player_id.should == @user1._id.to_s

      @game.add_player!(@user2)
      Game.find(@game._id).unit_at(10, 5).player_id.should == @user2._id.to_s
      Game.find(@game._id).base_at(11, 5).player_id.should == @user2._id.to_s
    end
  end

  describe '#user_credits(user) and #set_user_credits(user, credits)' do
    it 'should return nil if the user is not in the game' do
      @game.add_player!(@user1)
      @game.user_credits(@user2).should be_nil
      @game.set_user_credits(@user2, 400).should be_nil
    end

    it "should set and return the player's credits" do
      @game.add_player!(@user1)
      @game.add_player!(@user2)

      @game.set_user_credits(@user1, 200)
      @game.user_credits(@user1).should == 200

      @game.set_user_credits(@user2, 500)
      @game.user_credits(@user2).should == 500
    end
  end

  describe '#unit_at(x, y, slot = nil)' do
    it 'should return the unit at the given x and y location' do
      @game.unit_at(10, 5).should == @game.units[1]
    end

    it 'should return the unit at the given x, y, and slot location' do
      @game.units << Unit.new(:HeavyTank, 1, 8, 7, 10, nil, 0, 0, [
                              Unit.new(:Infantry, 1, 1, 1),
                              Unit.new(:Tank, 1, 1, 0)
      ])
      @game.unit_at(8, 7, 1).should == @game.units[2].loaded_units[1]
    end

    it 'should return nil if there is no unit at the given location' do
      @game.units << Unit.new(:HeavyTank, 1, 8, 7, 10, nil, 0, 0, [
                              Unit.new(:Infantry, 1, 1, 1),
                              Unit.new(:Tank, 1, 1, 0)
      ])
      @game.unit_at(3, 3).should be_nil
      @game.unit_at(3, 3, 0).should be_nil
      @game.unit_at(8, 7, 2).should be_nil
    end
  end

  describe '#base_at(x, y)' do
    it 'should return the base at the given x and y location' do
      @game.base_at(8, 3).should == @game.bases[0]
      @game.base_at(11, 5).should == @game.bases[1]
    end

    it 'should return nil if there is no base at the given location' do
      @game.base_at(9, 4).should be_nil
    end
  end

  describe '#capturing_at?(x, y)' do
    it 'should return false if there is no base being captured at the given location' do
      @game.capturing_at?(8, 3).should == false
    end

    it 'should return false if there is no base at the given location' do
      @game.capturing_at?(1, 1).should == false
    end

    it 'should return true if there is a base being captured at the given location' do
      @game.base_at(11, 5).start_capture('asdf', 1)
      @game.capturing_at?(11, 5).should == true
    end
  end

  describe '#terrain_at(x, y)' do
    it 'should return the terrain type at the given x and y location' do
      @game.terrain_at(7, 4).should == :sea
      @game.terrain_at(7, 5).should == :plains

      @game.map.tiles[7][9] = 3
      @game.terrain_at(9, 7).should == :woods
    end

    it "should return the modified terrain type if there is a terrain_modifier at the given x and y location" do
      @game.terrain_modifiers << TerrainModifier.new('road', 7, 5)
      @game.save

      @game.reload.terrain_at(7, 5).should == :road
    end

    it "should return the most recent modified terrain type if there is more than one terrain_modifier at the given x and y location" do
      @game.terrain_modifiers << TerrainModifier.new('plains', 7, 5)
      @game.reload.terrain_at(7, 5).should == :plains
      @game.terrain_modifiers << TerrainModifier.new('road', 7, 5)
      @game.save

      @game.reload.terrain_at(7, 5).should == :road
    end
  end

  describe "#unmodified_terrain_at(x, y)" do
    it "should return the terrain type at the given x and y location" do
      @game.unmodified_terrain_at(7, 4).should == :sea
      @game.unmodified_terrain_at(7, 5).should == :plains
    end

    it "should return the unmodified terrain type if there is a terrain_modifier at the given x and y location" do
      @game.terrain_modifiers << TerrainModifier.new('road', 7, 5)
      @game.save

      @game.reload.unmodified_terrain_at(7, 5).should == :plains
    end
  end

  describe '#rival_units' do
    it 'should return all units not belonging to the #current_user' do
      @game.add_player!(@user1)
      @game.units << Unit.new(:Infantry, 2, 8, 7)
      @game.rival_units.should include(@game.units[1])
      @game.rival_units.should include(@game.units[2])
      @game.rival_units.should_not include(@game.units[0])
    end
  end
end
