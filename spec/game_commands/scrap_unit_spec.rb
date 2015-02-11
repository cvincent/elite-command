require 'spec_helper'

describe ScrapUnit do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.add_player!(@user1)
    @game.add_player!(@user2)
    @game.set_user_credits(@user1, 100)
    @game.save
    @game.reload

    @call_expecting_error = ->(x, y, err, u = @user1) {
      lambda do
        ScrapUnit.new(@game, u, :x => x, :y => y).execute!
      end.should raise_error(CommandError, err)
    }

    @add_unit = ->(unit_type, x, y, player = 1) {
      @game.units << Unit.new(unit_type, player, x, y)
      @game.units.last.player_id = @game.players[player - 1].try(:to_s) || nil
      @game.units.last
    }
  end

  describe '#execute!' do
    it 'should fail if the acting user is not the current player' do
      @add_unit[:Infantry, 11, 5, 2]
      @call_expecting_error[11, 5, "Not user's turn.", @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(:status => 'win')
      @add_unit[:Infantry, 8, 3, 1]
      @call_expecting_error[8, 3, "Game not running."]
    end

    it 'should fail if x and y does not get an actual base' do
      @call_expecting_error[8, 4, "No such base."]
    end

    it 'should fail if x and y does not get a base owned by the player' do
      @add_unit[:Infantry, 5, 5, 1]
      @call_expecting_error[5, 5, "Targeted base is not friendly."]

      @add_unit[:Infantry, 11, 5, 1]
      @call_expecting_error[11, 5, "Targeted base is not friendly."]
    end

    it 'should fail if x and y does not get an actual unit' do
      @call_expecting_error[8, 3, "No such unit."]
    end

    it 'should fail if x and y does not get a unit owned by the player' do
      @add_unit[:Infantry, 8, 3, 2]
      @call_expecting_error[8, 3, "Not user's unit."]
    end

    it "should fail if x and y does not get a unit which can be built/repaired at the base" do
      @add_unit[:Bomber, 8, 3, 1]
      @call_expecting_error[8, 3, "Unit cannot be scrapped there."]
    end

    it "should fail if unit at x and y does not have 0 attacks" do
      u = @add_unit[:Humvee, 8, 3, 1]
      u.health = 6
      u.attacks = 1
      @call_expecting_error[8, 3, "Cannot scrap after attacking."]
    end

    it 'should scrap the unit for half of its price - 10% for each missing health point' do
      @add_unit[:Infantry, 8, 3, 1]
      @game.units.last.health -= 6
      ScrapUnit.new(@game, @user1, x: 8, y: 3).execute!

      @game.reload.unit_at(8, 3).should be_nil
      @game.user_credits(@user1).should == 115
    end
  end

  describe '#unexecute!' do
    it 'should place the unit back on the map with its original stats and take back the scrap credits' do
      @add_unit[:Infantry, 8, 3, 1]
      @game.units.last.health -= 6
      @game.units.last.movement_points = 3
      
      scrap = ScrapUnit.new(@game, @user1, x: 8, y: 3)
      scrap.execute!
      scrap.unexecute!

      @game.reload.unit_at(8, 3).unit_type.should == :Infantry
      @game.unit_at(8, 3).health.should == 4
      @game.unit_at(8, 3).movement_points.should == 3
      @game.unit_at(8, 3).attacks.should == 0
      @game.user_credits(@user1).should == 100
    end
  end
end
