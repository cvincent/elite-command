require 'spec_helper'

describe MoveUnit do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.unit_at(8, 4).moved = false
    @game.add_player!(@user1)

    @call_expecting_error = ->(err, x, y, dx, dy, user = @user1) {
      lambda do
        MoveUnit.new(
          @game, user, unit_x: x, unit_y: y, dest_x: dx, dest_y: dy
        ).execute!
      end.should raise_error(CommandError, err)
    }
  end

  describe '#execute!' do
    it 'should fail if the acting user is not the current player' do
      @call_expecting_error["Not user's turn.", 8, 4, 8, 5, @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(:status => 'win')
      @call_expecting_error["Game not running.", 8, 4, 8, 5]
    end

    it 'should fail if unit_x, unit_y, unit_slot does not get an actual unit' do
      @call_expecting_error["No such unit.", 9, 4, 9, 5]
    end

    it 'should fail if unit_x, unit_y, unit_slot does not get unit owned by #current_user' do
      @call_expecting_error["Not user's unit.", 10, 5, 9, 5]
    end

    it 'should fail if unit has no movement points' do
      @game.unit_at(8, 4).movement_points = 0
      @game.save
      @game = Game.find(@game._id)

      @call_expecting_error["No movement points.", 8, 4, 8, 5]
    end

    it 'should fail if unit cannot reach the desired location' do
      @call_expecting_error["Invalid destination.", 8, 4, 10, 8]
    end

    it 'should fail if destination is occupied' do
      @call_expecting_error["Invalid destination.", 8, 4, 10, 5]
    end

    it 'should fail if destination is not passable by the unit' do
      @call_expecting_error["Invalid destination.", 8, 4, 7, 4]
    end

    it 'should fail if the unit is capturing a base' do
      @game.units << Unit.new(:Infantry, 1, 5, 5)
      @game.units.last.player_id = @user1._id.to_s
      @game.base_at(5, 5).start_capture(@user1._id.to_s, 1)

      @call_expecting_error["Unit is capturing a base.", 5, 5, 6, 5]
    end

    it "should update the unit's location, movement points, and moved flag if successful" do
      MoveUnit.new(@game, @user1, :unit_x => 8, :unit_y => 4, :dest_x => 9, :dest_y => 6).execute!
      @game.units[0].x.should == 9
      @game.units[0].y.should == 6
      @game.units[0].movement_points.should == 3
      @game.units[0].moved.should == true
    end

    it "should raise the unit's attack count to the maximum if the unit has an attack_type of :exclusive" do
      @game.units << Unit.new(:Artillery, 1, 7, 7)
      @game.units.last.player_id = @game.players[0].to_s

      MoveUnit.new(@game, @user1, :unit_x => 7, :unit_y => 7, :dest_x => 7, :dest_y => 8).execute!
      @game.units.last.x.should == 7
      @game.units.last.y.should == 8
      @game.units.last.movement_points.should == 4
      @game.units.last.attacks.should == 1
    end

    it "should update the x and y of any loaded units if successful" do
      l1 = Unit.new(:Infantry, 1, 10, 11)
      l1.player_id = @game.players[0].to_s
      l2 = Unit.new(:Infantry, 1, 10, 11)
      l2.player_id = @game.players[0].to_s

      @game.units << Unit.new(:Transport, 1, 10, 11)
      @game.units.last.loaded_units << l1
      @game.units.last.loaded_units << l2
      @game.units.last.player_id = @game.players[0].to_s

      MoveUnit.new(@game, @user1, :unit_x => 10, :unit_y => 11, :dest_x => 11, :dest_y => 15).execute!

      l1 = @game.unit_at(11, 15, 0)
      l1.x.should == 11
      l1.y.should == 15

      l2 = @game.unit_at(11, 15, 1)
      l2.x.should == 11
      l2.y.should == 15
    end

    it "should allow moving of units out of a transport" do
      l1 = Unit.new(:Infantry, 1, 10, 10)
      l1.player_id = @game.players[0].to_s
      l2 = Unit.new(:Ranger, 1, 10, 10)
      l2.player_id = @game.players[0].to_s

      @game.units << Unit.new(:Transport, 1, 10, 10)
      @game.units.last.loaded_units << l1
      @game.units.last.loaded_units << l2
      @game.units.last.player_id = @game.players[0].to_s

      MoveUnit.new(@game, @user1, :unit_x => 10, :unit_y => 10, :unit_slot => 0, :dest_x => 9, :dest_y => 8).execute!

      t = @game.unit_at(10, 10)
      t.loaded_units.size.should == 1
      t.loaded_units[0].unit_type.should == :Ranger

      l1 = @game.unit_at(9, 8)
      l1.should_not be_nil
      l1.movement_points.should == 3
    end
  end

  describe '#unexecute' do
    it 'should return the moved unit to the state it was in before #execute' do
      unit_before = @game.units[0].dup
      unit_before.should_not == @game.units[0].dup

      c = MoveUnit.new(@game, @user1, :unit_x => 8, :unit_y => 4, :dest_x => 9, :dest_y => 6)
      c.execute!

      @game.units[0].x.should_not == unit_before.x
      @game.units[0].y.should_not == unit_before.y
      @game.units[0].movement_points.should_not == unit_before.movement_points
      @game.units[0].moved.should == true

      c.unexecute!
      @game.units[0].x.should == unit_before.x
      @game.units[0].y.should == unit_before.y
      @game.units[0].movement_points.should == unit_before.movement_points
      @game.units[0].moved.should == false
    end

    it "should return the x and y of any loaded units to the previous x and y" do
      l1 = Unit.new(:Infantry, 1, 10, 11)
      l1.player_id = @game.players[0].to_s
      l2 = Unit.new(:Infantry, 1, 10, 11)
      l2.player_id = @game.players[0].to_s

      @game.units << Unit.new(:Transport, 1, 10, 11)
      @game.units.last.loaded_units << l1
      @game.units.last.loaded_units << l2
      @game.units.last.player_id = @game.players[0].to_s

      c = MoveUnit.new(@game, @user1, :unit_x => 10, :unit_y => 11, :dest_x => 11, :dest_y => 15)
      c.execute!
      c.unexecute!

      l1 = @game.unit_at(10, 11, 0)
      l1.x.should == 10
      l1.y.should == 11

      l2 = @game.unit_at(10, 11, 1)
      l2.x.should == 10
      l2.y.should == 11
    end

    it "should work for units moved out of a transport" do
      l1 = Unit.new(:Infantry, 1, 10, 10)
      l1.player_id = @game.players[0].to_s
      l2 = Unit.new(:Ranger, 1, 10, 10)
      l2.player_id = @game.players[0].to_s

      @game.units << Unit.new(:Transport, 1, 10, 10)
      @game.units.last.loaded_units << l1
      @game.units.last.loaded_units << l2
      @game.units.last.player_id = @game.players[0].to_s

      c = MoveUnit.new(@game, @user1, :unit_x => 10, :unit_y => 10, :unit_slot => 0, :dest_x => 9, :dest_y => 8)
      c.execute!
      c.unexecute!

      @game.unit_at(9, 8).should be_nil

      t = @game.unit_at(10, 10)
      t.loaded_units.size.should == 2
      t.loaded_units[0].unit_type.should == :Infantry
      t.loaded_units[0].should == @game.unit_at(10, 10, 0)

      l1 = @game.unit_at(10, 10, 0)
      l1.movement_points.should == 9
      l1.x.should == 10
      l1.y.should == 10
    end
  end
end

