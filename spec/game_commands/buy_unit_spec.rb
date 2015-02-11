require 'spec_helper'

describe BuyUnit do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.add_player!(@user1)
    @game.add_player!(@user2)

    @call_expecting_error = ->(err, x, y, unit_type = :Infantry, user = @user1) {
      lambda do
        BuyUnit.new(@game, user, x: x, y: y, unit_type: unit_type).execute!
      end.should raise_error(CommandError, err)
    }
  end

  describe '#execute' do
    it 'should fail if the acting user is not the current player' do
      @call_expecting_error["Not user's turn.", 8, 3, :Infantry, @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(:status => 'win')
      @call_expecting_error["Game not running.", 8, 3, :Infantry]
    end

    it 'should fail if x, y does not get a base' do
      @call_expecting_error["No such base.", 7, 5]
    end

    it 'should fail if x, y does not get a base belonging to the player' do
      @call_expecting_error["Not user's base.", 11, 5]
    end

    it "should fail if the base is occupied" do
      @game.units << Unit.new(:Infantry, 1, 8, 3)
      @call_expecting_error["Base is occupied.", 8, 3]
    end

    it 'should fail if the base cannot build the unit type' do
      @call_expecting_error["Base cannot build that unit.", 8, 3, :Fighter]
    end

    it "should fail if the player does not have enough credits to build the unit type" do
      @game.set_user_credits(@user1, 50)
      @call_expecting_error["Not enough credits.", 8, 3]
    end

    it "should fail if the creator is a free user and the unit type is not free" do
      @game.game_type = 'free'
      @user1.save
      @game.set_user_credits(@user1, 300)
      @call_expecting_error["Unit not allowed in free game.", 8, 3, :Sniper]
    end

    it "should not fail if the creator is a free user and the unit type is free" do
      @user1.account_type = 'free'
      @user1.save

      lambda do
        BuyUnit.new(@game, @user1, x: 8, y: 3, unit_type: :Infantry).execute!
      end.should_not raise_error
    end

    it "should create a new unit with 0 movement points, summoning_sickness,
        and no remaining attack phases at the base location
        subtracting the cost from the player's credits" do

      @game.set_user_credits(@user1, 100)

      BuyUnit.new(@game, @user1, x: 8, y: 3, unit_type: :Infantry).execute!

      @game.user_credits(@user1).should == 25

      u = @game.unit_at(8, 3)
      u.should_not be_nil
      u.health.should == 10
      u.movement_points.should == 0
      u.has_enough_attack_points_to_attack?.should == false
      u.summoning_sickness.should == true
      u.player.should == 1
    end
  end

  describe '#unexecute' do
    it "should remove the unit and reimburse the player's credits" do
      @game.set_user_credits(@user1, 100)
      bu = BuyUnit.new(@game, @user1, x: 8, y: 3, unit_type: :Infantry)
      bu.execute!

      bu.unexecute!

      @game.user_credits(@user1).should == 100
      @game.unit_at(8, 3).should be_nil
    end
  end
end
