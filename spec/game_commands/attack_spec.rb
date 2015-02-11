require 'spec_helper'

describe Attack do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )

    @game.units << Unit.new(:Infantry, 1, 9, 9)
    @game.units << Unit.new(:Infantry, 2, 10, 9)

    @game.add_player!(@user1)
    @game.add_player!(@user2)

    @call_expecting_error = ->(err, unit_x, unit_y, target_x, target_y, user = @user1) {
      lambda do
        Attack.new(
          @game, user, :unit_x => unit_x, :unit_y => unit_y, :target_x => target_x, :target_y => target_y
        ).execute!
      end.should raise_error(CommandError, err)
    }

    @add_unit = ->(unit_type, x, y, player = 1) {
      @game.units << Unit.new(unit_type, player, x, y)
      @game.units.last.player_id = @game.players[player - 1].try(:to_s) || nil
      @game.units.last.moved = false
      @game.units.last
    }
  end

  describe '#execute!' do
    it 'should fail if the acting user is not the Game#current_user' do
      @call_expecting_error["Not user's turn.", 10, 9, 9, 9, @user2]
    end

    it "should fail if the game is already concluded" do
      @game.update_attributes(:status => 'win')
      @call_expecting_error["Game not running.", 10, 9, 9, 9]
    end

    it 'should fail if no unit is found at unit_x, unit_y' do
      @call_expecting_error["No such unit.", 10, 8, 10, 9]
    end

    it 'should fail if unit at unit_x, unit_y is not owned by Game#current_user' do
      @add_unit[:Infantry, 10, 8, 2]
      @call_expecting_error["Not user's unit.", 10, 8, 10, 9]
    end

    it 'should fail if unit at target_x, target_y does not exist' do
      @call_expecting_error["No such target.", 9, 9, 8, 9]
    end

    it 'should fail if unit at target_x, target_y is a friendly unit' do
      @add_unit[:Infantry, 10, 8, 1]
      @call_expecting_error["Targeted unit is friendly.", 10, 8, 9, 9]
    end

    it 'should fail if the attacker has no attack phases left' do
      @game.unit_at(9, 9).attacks = @game.unit_at(9, 9).attack_phases
      @call_expecting_error["Unit has no attack phases left.", 9, 9, 10, 9]
    end

    it 'should fail if the attacker has :exclusive attack_type and has moved' do
      @game.units << Unit.new(:Artillery, 1, 9, 7, 10, 1)
      @game.units.last.moved = true
      @game.units.last.player_id = @user1._id.to_s

      @call_expecting_error["Unit not allowed to attack.", 9, 7, 10, 9]
    end

    it "should fail if the target is inside the attacker's minimum range" do
      # Mortar has a minimum range of 2
      @add_unit[:Mortar, 10, 8, 1]
      @call_expecting_error["Targeted unit is not within range.", 10, 8, 10, 9]
    end

    it "should fail if the target is outside the attacker's maximum range" do
      @call_expecting_error["Targeted unit is not within range.", 8, 4, 10, 9]
    end

    it "should fail if the attacker is unable to attack the target unit_type" do
      @add_unit[:Fighter, 7, 5, 2]
      @call_expecting_error["Unit unable to attack target.", 8, 4, 7, 5]
    end

    it "should fail if the attacker is capturing a base" do
      @add_unit[:Infantry, 11, 5, 1]
      @game.base_at(11, 5).start_capture(@user1._id.to_s, 1)

      @call_expecting_error["Unit is capturing a base.", 11, 5, 10, 5]
    end

    it "should perform attack and counterattack damage if attacking a valid target which can counterattack" do
      @add_unit[:Infantry, 7, 5, 2]

      @game.unit_at(8, 4).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(7, 5), :plains, false
      ).once.and_return(3)

      @game.unit_at(7, 5).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 4), :plains
      ).once.and_return(6)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 4, :target_x => 7, :target_y => 5).execute

      @game.unit_at(8, 4).health.should == 4
      @game.unit_at(7, 5).health.should == 7
    end

    it "should pass whether the defender is capturing a base" do
      @add_unit[:Infantry, 8, 3, 2]
      @game.base_at(8, 3).start_capture('asdf', 2)

      @game.unit_at(8, 4).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 3), :base, true
      ).once.and_return(3)

      @game.unit_at(8, 3).should_receive(:calculate_damage).with(
        :base, @game.unit_at(8, 4), :plains
      ).once.and_return(6)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 4, :target_x => 8, :target_y => 3).execute

      @game.unit_at(8, 4).health.should == 4
      @game.unit_at(8, 3).health.should == 7
    end

    it "should not perform a counterattack if the attacker is inside the defender's minimum range" do
      @add_unit[:Mortar, 7, 5, 2]

      @game.unit_at(8, 4).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(7, 5), :plains, false
      ).once.and_return(3)

      @game.unit_at(7, 5).should_receive(:calculate_damage).never

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 4, :target_x => 7, :target_y => 5).execute

      @game.unit_at(8, 4).health.should == 10
      @game.unit_at(7, 5).health.should == 7
    end

    it "should not perform a counterattack if the attacker is outside the defender's maximum range" do
      @add_unit[:Mortar, 8, 8, 1]

      @game.unit_at(8, 8).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(10, 9), :plains, false
      ).once.and_return(8)

      @game.unit_at(10, 9).should_receive(:calculate_damage).never

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 8, :target_x => 10, :target_y => 9).execute

      @game.unit_at(8, 8).health.should == 10
      @game.unit_at(10, 9).health.should == 2
    end

    it "should not perform a counterattack if the attacker is an armor_type which the defender can't attack" do
      @add_unit[:Bomber, 7, 6, 1]
      @add_unit[:Infantry, 7, 5, 2]

      @game.unit_at(7, 6).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(7, 5), :plains, false
      ).once.and_return(5)

      @game.unit_at(7, 5).should_receive(:calculate_damage).never

      Attack.new(@game, @user1, :unit_x => 7, :unit_y => 6, :target_x => 7, :target_y => 5).execute

      @game.unit_at(7, 6).health.should == 10
      @game.unit_at(7, 5).health.should == 5
    end

    it "should still perform a counterattack if the defender has no attacks left" do
      @add_unit[:Infantry, 7, 5, 2]

      @game.unit_at(8, 4).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(7, 5), :plains, false
      ).once.and_return(3)

      @game.unit_at(7, 5).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 4), :plains
      ).once.and_return(6)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 4, :target_x => 7, :target_y => 5).execute

      @game.unit_at(8, 4).health.should == 4
      @game.unit_at(7, 5).health.should == 7
    end

    it "should still perform a counterattack if the defender has :exclusive attack_type and #moved == true" do
      @add_unit[:Mortar, 8, 7, 1]
      defender = @add_unit[:Mortar, 6, 7, 2]
      defender.moved = true

      @game.unit_at(8, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(6, 7), :plains, false
      ).once.and_return(3)

      @game.unit_at(6, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 7), :plains
      ).once.and_return(6)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 7, :target_x => 6, :target_y => 7).execute

      @game.unit_at(8, 7).health.should == 4
      @game.unit_at(6, 7).health.should == 7
    end

    it "should remove the defender if it dies" do
      @add_unit[:Mortar, 8, 7, 1]
      u2 = @add_unit[:Mortar, 6, 7, 2]

      @game.unit_at(8, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(6, 7), :plains, false
      ).once.and_return(11)

      @game.unit_at(6, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 7), :plains
      ).once.and_return(6)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 7, :target_x => 6, :target_y => 7).execute

      @game.unit_at(8, 7).health.should == 4
      @game.unit_at(6, 7).should be_nil
      @game.units.should_not include(u2)
    end

    it "should remove the attacker if it dies" do
      u1 = @add_unit[:Mortar, 8, 7, 1]
      @add_unit[:Mortar, 6, 7, 2]

      @game.unit_at(8, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(6, 7), :plains, false
      ).once.and_return(3)

      @game.unit_at(6, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 7), :plains
      ).once.and_return(10)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 7, :target_x => 6, :target_y => 7).execute

      @game.unit_at(8, 7).should be_nil
      @game.units.should_not include(u1)
      @game.unit_at(6, 7).health.should == 7
    end

    it "should reset the base's capture state if the defender dies and was capturing" do
      u2 = @add_unit[:Infantry, 8, 3, 2]
      u2.health = 5

      @game.base_at(8, 3).start_capture('asdf', 2)

      @game.unit_at(8, 3).should_receive(:calculate_damage).with(
        :base, @game.unit_at(8, 4), :plains
      ).once.and_return(6)

      @game.unit_at(8, 4).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 3), :base, true
      ).once.and_return(6)

      Attack.new(@game, @user1, :unit_x => 8, :unit_y => 4, :target_x => 8, :target_y => 3).execute

      @game.unit_at(8, 4).health.should == 4
      @game.unit_at(8, 3).should be_nil
      @game.units.should_not include(u2)
      @game.base_at(8, 3).capture_phase.should be_nil
    end

    it "should drop the attacker's movement points to 0 if the unit type has an attack_type of :exclusive" do
      u1 = @add_unit[:Mortar, 9, 6, 1]

      @game.unit_at(9, 6).should_receive(:calculate_damage).once.and_return(6)
      @game.unit_at(10, 5).should_receive(:calculate_damage).never

      Attack.new(@game, @user1, :unit_x => 9, :unit_y => 6, :target_x => 10, :target_y => 5).execute

      @game.unit_at(9, 6).health.should == 10
      @game.unit_at(9, 6).movement_points.should == 0
      @game.unit_at(10, 5).health.should == 4
    end

    it "should drop the attacker's movement points to 0 if the unit type has an attack_type of :move_attack" do
      u1 = @add_unit[:Infantry, 10, 6, 1]

      @game.unit_at(10, 6).should_receive(:calculate_damage).once.and_return(6)
      @game.unit_at(10, 5).should_receive(:calculate_damage).once.and_return(3)

      Attack.new(@game, @user1, :unit_x => 10, :unit_y => 6, :target_x => 10, :target_y => 5).execute

      @game.unit_at(10, 6).health.should == 7
      @game.unit_at(10, 6).movement_points.should == 0
      @game.unit_at(10, 5).health.should == 4
    end

    it "should not deduct attacker movement points if the unit type has an attack_type of :free" do
      u1 = @add_unit[:Humvee, 10, 6, 1]

      @game.unit_at(10, 6).should_receive(:calculate_damage).once.and_return(6)
      @game.unit_at(10, 5).should_receive(:calculate_damage).once.and_return(3)

      Attack.new(@game, @user1, :unit_x => 10, :unit_y => 6, :target_x => 10, :target_y => 5).execute

      @game.unit_at(10, 6).health.should == 7
      @game.unit_at(10, 6).movement_points.should == 15
      @game.unit_at(10, 5).health.should == 4
    end

    it "should increment the attack count for the attacker and flag it as having attacked" do
      u1 = @add_unit[:Humvee, 10, 6, 1]

      @game.unit_at(10, 6).should_receive(:calculate_damage).once.and_return(6)
      @game.unit_at(10, 5).should_receive(:calculate_damage).once.and_return(3)

      Attack.new(@game, @user1, :unit_x => 10, :unit_y => 6, :target_x => 10, :target_y => 5).execute

      @game.unit_at(10, 6).health.should == 7
      @game.unit_at(10, 6).attacks.should == 1
      @game.unit_at(10, 6).attacked.should be_true
      @game.unit_at(10, 5).health.should == 4
    end

    it "should increment the flank penalty for the defender" do
      u1 = @add_unit[:Humvee, 10, 6, 1]

      @game.unit_at(10, 6).should_receive(:calculate_damage).once.and_return(6)
      @game.unit_at(10, 5).should_receive(:calculate_damage).once.and_return(3)

      Attack.new(@game, @user1, :unit_x => 10, :unit_y => 6, :target_x => 10, :target_y => 5).execute

      @game.unit_at(10, 6).health.should == 7
      @game.unit_at(10, 6).attacks.should == 1
      @game.unit_at(10, 5).health.should == 4
      @game.unit_at(10, 5).flank_penalty.should == 1
    end

    it "should return the amount of damage done by each unit" do
      @add_unit[:Mortar, 8, 7, 1]
      @add_unit[:Mortar, 6, 7, 2]

      @game.unit_at(8, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(6, 7), :plains, false
      ).once.and_return(3)

      @game.unit_at(6, 7).should_receive(:calculate_damage).with(
        :plains, @game.unit_at(8, 7), :plains
      ).once.and_return(10)

      ret = Attack.new(@game, @user1, :unit_x => 8, :unit_y => 7, :target_x => 6, :target_y => 7).execute

      ret.should == { :attacker_damage => 3, :defender_damage => 10 }
    end
  end

  describe "#unexecute" do
    it "should raise IrreversibleCommand" do
      lambda do
        ret = Attack.new(
          @game, @user1, :unit_x => 8, :unit_y => 7, :target_x => 6, :target_y => 7
        ).unexecute
      end.should raise_error(IrreversibleCommand)
    end
  end
end

