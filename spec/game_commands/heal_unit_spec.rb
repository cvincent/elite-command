require 'spec_helper'

describe HealUnit do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.add_player!(@user1)
    @game.add_player!(@user2)

    @call_expecting_error = ->(x, y, err, u = @user1) {
      lambda do
        HealUnit.new(@game, u, :x => x, :y => y).execute!
      end.should raise_error(CommandError, err)
    }

    @add_unit = ->(unit_type, x, y, player = 1) {
      @game.units << Unit.new(unit_type, player, x, y)
      @game.units.last.player_id = @game.players[player - 1].try(:to_s) || nil
      @game.units.last
    }
  end

  describe "#execute!" do
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
      @call_expecting_error[8, 3, "Unit cannot be repaired there."]
    end

    it "should fail if x and y does not get a unit which has been damaged" do
      @add_unit[:Infantry, 8, 3, 1]
      @call_expecting_error[8, 3, "Unit has not taken damage."]
    end

    it "should fail if unit at x and y has attacked" do
      u = @add_unit[:Humvee, 8, 3, 1]
      u.health = 6
      u.attacks = 1
      u.attacked = true
      @call_expecting_error[8, 3, "Cannot heal after attacking."]
    end

    it "should fail if the unit has already healed this turn" do
      u = @add_unit[:Infantry, 8, 3, 1]
      @game.units.last.health -= 6
      HealUnit.new(@game, @user1, x: 8, y: 3).execute!

      u.healed.should be_true

      @call_expecting_error[8, 3, "Unit has already healed this turn."]
    end

    it "should heal 1/2 of the unit's missing health and take away its remaining attacks and moves" do
      @add_unit[:Infantry, 8, 3, 1]
      @game.units.last.health -= 6
      HealUnit.new(@game, @user1, x: 8, y: 3).execute!

      @game.reload.unit_at(8, 3).health.should == 7
      @game.unit_at(8, 3).movement_points.should == 0
      @game.unit_at(8, 3).attacks.should == 1
    end

    it "should succeed if the unit has used its attack phases but has not actually attacked (for attack type :exclusive)" do
      @add_unit[:HeavyArtillery, 8, 3, 1]
      @game.units.last.health -= 6
      @game.units.last.attacked = false
      @game.units.last.attacks = 1
      HealUnit.new(@game, @user1, x: 8, y: 3).execute!

      @game.reload.unit_at(8, 3).health.should == 7
      @game.unit_at(8, 3).movement_points.should == 0
      @game.unit_at(8, 3).attacks.should == 1
    end
  end

  describe "unexecute!" do
    it "should take away the amount of health which was healed and give back its attacks and moves" do
      @add_unit[:Infantry, 8, 3, 1]
      @game.units.last.health -= 6
      @game.units.last.movement_points = 3

      heal = HealUnit.new(@game, @user1, x: 8, y: 3)
      heal.execute!
      heal.unexecute!

      @game.reload.unit_at(8, 3).health.should == 4
      @game.unit_at(8, 3).movement_points.should == 3
      @game.unit_at(8, 3).attacks.should == 0
    end
  end
end
