require 'spec_helper'

describe LoadUnit do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.add_player!(@user1)

    @game.units.each do |u|
      u.summoning_sickness = false
    end

    @game.units << Unit.new(:Transport, 1, 7, 4)
    @game.units.last.player_id = @user1._id.to_s
    @game.units.last.summoning_sickness = false

    @game.units << Unit.new(:Transport, 2, 10, 4)
    @game.units.last.player_id = @user2._id.to_s
    @game.units.last.summoning_sickness = false

    @call_expecting_error = ->(err, x, y, tx, ty, user = @user1) {
      lambda do
        LoadUnit.new(
          @game, user, x: x, y: y, tx: tx, ty: ty
        ).execute!
      end.should raise_error(CommandError, err)
    }

    @game.save
    @game = Game.find(@game.id)
  end

  describe '#execute!' do
    it "should fail if the acting user is not the current player" do
      @call_expecting_error["Not user's turn.", 10, 5, 10, 4, @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(:status => 'win')
      @call_expecting_error["Game not running.", 8, 4, 7, 4]
    end

    it "should fail if x and y does not get an actual unit" do
      @call_expecting_error["No such unit.", 7, 5, 7, 4]
    end

    it "should fail if x and y does not get unit owned by #current_user" do
      @call_expecting_error["Not user's unit.", 10, 5, 10, 4]
    end

    it "should fail if x and y does not get unit owned by #current_user" do
      @call_expecting_error["Not user's unit.", 10, 5, 10, 4]
    end

    it "should fail if x and y unit is capturing" do
      @game.units << Unit.new(:Infantry, 1, 8, 3)
      @game.units.last.player_id = @user1._id.to_s
      @game.units.last.summoning_sickness = false
      @game.base_at(8, 3).start_capture(@user1._id.to_s, 1)

      @game.units << Unit.new(:Transport, 1, 7, 3)
      @game.units.last.player_id = @user1._id.to_s
      @game.units.last.summoning_sickness = false
      @game.save

      @call_expecting_error["Unit is capturing a base.", 8, 3, 7, 3]
    end

    it "should fail if the unit is not within a single tile of the transport" do
      @game.units << Unit.new(:Infantry, 1, 8, 6)
      @game.units.last.player_id = @user1._id.to_s
      @game.units.last.summoning_sickness = false
      @game.save

      @call_expecting_error["Unit not within range of the transport.", 8, 6, 7, 4]
    end

    it "should fail if tx and ty does not get an actual unit" do
      @call_expecting_error["No such unit.", 8, 4, 7, 3]
    end

    it "should fail if tx and ty does not get unit owned by #current_user" do
      @game.units << Unit.new(:Transport, 2, 7, 3)
      @game.units.last.player_id = @user2._id.to_s
      @game.units.last.summoning_sickness = false
      @game.save

      @call_expecting_error["Not user's unit.", 8, 4, 7, 3]
    end

    it "should fail if the transport does not have enough capacity" do
      6.times do
        @game.unit_at(7, 4).loaded_units << Unit.new(:Infantry, 1, 7, 4)
        @game.units.last.summoning_sickness = false
      end
      @game.save

      @call_expecting_error["Not enough space.", 8, 4, 7, 4]
    end

    it "should fail if the transport cannot transport the armor_type" do
      @game.units << Unit.new(:Bomber, 1, 6, 3)
      @game.units.last.player_id = @user1._id.to_s
      @game.units.last.summoning_sickness = false
      @game.save

      @call_expecting_error["Cannot load that unit type.", 6, 3, 7, 4]
    end

    it "should fail if x and y unit has summoning_sickness" do
      @game.unit_at(8, 4).summoning_sickness = true
      @game.save

      @call_expecting_error["Unit has summoning sickness.", 8, 4, 7, 4]
    end

    it "should remove the unit from the starting location if successful" do
      LoadUnit.new(@game, @user1, x: 8, y: 4, tx: 7, ty: 4).execute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).should be_nil
    end

    it "should add the unit to the transport's loaded_units if successful" do
      LoadUnit.new(@game, @user1, x: 8, y: 4, tx: 7, ty: 4).execute!

      @game = Game.find(@game.id)
      @game.unit_at(7, 4, 0).should_not be_nil
      @game.unit_at(7, 4, 0).unit_type.should == :Infantry
    end

    it "should set the unit's x and y to the transport's x and y if successful" do
      LoadUnit.new(@game, @user1, x: 8, y: 4, tx: 7, ty: 4).execute!

      @game = Game.find(@game.id)
      @game.unit_at(7, 4, 0).x.should == 7
      @game.unit_at(7, 4, 0).y.should == 4
    end
  end

  describe '#unexecute' do
    it "should remove the unit from the transport and place it back where it started" do
      c = LoadUnit.new(@game, @user1, x: 8, y: 4, tx: 7, ty: 4)
      c.execute!
      @game = Game.find(@game.id)

      c.unexecute!
      
      @game = Game.find(@game.id)
      @game.unit_at(8, 4).should_not be_nil
      @game.unit_at(7, 4, 0).should be_nil
    end
  end
end
