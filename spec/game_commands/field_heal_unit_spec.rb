require 'spec_helper'

describe FieldHealUnit do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.add_player!(@user1)
    @game.add_player!(@user2)

    @call_expecting_error = ->(x, y, tx, ty, err, u = @user1) {
      lambda do
        FieldHealUnit.new(@game, u, x: x, y: y, tx: tx, ty: ty).execute!
      end.should raise_error(CommandError, err)
    }

    @add_unit = ->(unit_type, x, y, player = 1) {
      @game.units << Unit.new(unit_type, player, x, y)
      @game.units.last.player_id = @game.players[player - 1].try(:to_s) || nil
      @game.units.last
    }

    @medic = @add_unit[:Medic, 8, 6]

    @damaged_unit = @add_unit[:Infantry, 8, 7]
    @damaged_unit.health = 5

    @far_unit = @add_unit[:Infantry, 6, 6]
    @far_unit.health = 5

    @non_healable_unit = @add_unit[:Tank, 7, 6]
    @non_healable_unit.health = 5

    @enemy_unit = @add_unit[:Infantry, 7, 7, 2]
    @enemy_unit.health = 5
  end

  describe '#execute!' do
    it "should fail if the acting user is not the current player" do
      @call_expecting_error[8, 6, 8, 7, "Not user's turn.", @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(:status => 'win')
      @call_expecting_error[8, 6, 8, 7, "Game not running."]
    end

    it "should fail if x and y does not get an actual unit" do
      @call_expecting_error[9, 8, 8, 7, "No such unit."]
    end

    it "should fail if x and y does not get a unit owned by the player" do
      @add_unit[:Medic, 8, 10, 2]
      u = @add_unit[:Infantry, 9, 10, 2]
      u.health = 5

      @call_expecting_error[8, 10, 9, 10, "Not user's unit."]
    end

    it "should fail if the unit at x and y does not have 0 attacks" do
      @medic.attacks = 1
      @call_expecting_error[8, 6, 8, 7, "Cannot heal after attacking."]
    end

    it "should fail if tx and ty does not get an actual unit" do
      @call_expecting_error[8, 6, 9, 6, "No such unit."]
    end

    it "should fail if tx and ty does not get a unit owned by the player" do
      @call_expecting_error[8, 6, 7, 7, "Not user's unit."]
    end

    it "should fail if tx and ty does not get a unit which has been damaged" do
      @add_unit[:Infantry, 9, 6]
      @call_expecting_error[8, 6, 9, 6, "Unit has not taken damage."]
    end

    it "should fail if tx and ty does not get a unit which can be healed by the unit at x and y" do
      @call_expecting_error[8, 6, 7, 6, "Cannot heal that unit type."]
    end

    it "should fail if tx and ty is not adjacent to x and y" do
      @call_expecting_error[8, 6, 6, 6, "Unit not within range."]
    end

    it "should heal 1/3 of the target unit's missing health" do
      FieldHealUnit.new(@game, @user1, x: 8, y: 6, tx: 8, ty: 7).execute!
      @game.reload.unit_at(8, 7).health.should == 7
      @game.unit_at(8, 7).movement_points.should == 9
      @game.unit_at(8, 7).attacks.should == 0
    end

    it "should take away the acting unit's remaining attacks and moves" do
      FieldHealUnit.new(@game, @user1, x: 8, y: 6, tx: 8, ty: 7).execute!
      @game.reload.unit_at(8, 6).movement_points.should == 0
      @game.unit_at(8, 6).attacks.should == 1
    end
  end

  describe "unexecute!" do
    it "should take away the amount of health which was healed and give back the healer's attacks and moves" do
      heal = FieldHealUnit.new(@game, @user1, x: 8, y: 6, tx: 8, ty: 7)
      heal.execute!
      heal.unexecute!

      @game.reload.unit_at(8, 7).health.should == 5
      @game.unit_at(8, 6).movement_points.should == 9
      @game.unit_at(8, 6).attacks.should == 0
    end
  end
end
