require 'spec_helper'

describe EndTurn do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @user3 = Fabricate(:user)

    @game = Game.create(:name => 'test', :map => Fabricate(:basic_1v1v1_map), :time_limit => 1.hour)

    @game.add_player!(@user1)
    @game.add_player!(@user2)
    @game.add_player!(@user3)

    @add_unit = ->(x, y, user = @user1, unit_type = :Infantry) {
      @game.units << Unit.new(unit_type, @game.players.index(user._id) + 1, x, y)
      @game.units.last.player_id = user._id.to_s
      @game.units.last.moved = false
      @game.units.last
    }

    @defeat_user2 = Proc.new do
      @game.units.delete(@game.unit_at(10, 11))
      @add_unit[11, 10]
      @add_unit[12, 10]
      @add_unit[11, 11]
      @add_unit[9, 13]
    end

    @defeat_user3 = Proc.new do
      @game.units.delete(@game.unit_at(7, 9))
      @add_unit[7, 10]
      @add_unit[8, 10]
      @add_unit[7, 11]
    end
  end

  describe "#execute" do
    it "should fail if user is not current player" do
      lambda do
        EndTurn.new(@game, @user2).execute!
      end.should raise_error(CommandError, "Not user's turn.")
    end

    it "should fail if the game is already concluded" do
      @game.update_attributes(:status => 'win')

      lambda do
        EndTurn.new(@game, @user1).execute!
      end.should raise_error(CommandError, "Game not running.")
    end

    it "should reset the player's skip count to 0" do
      @game.increment_player_skip_count(@user1)
      @game.save
      @game.reload.player_skip_count(@user1).should == 1

      EndTurn.new(@game, @user1).execute!

      @game.reload.player_skip_count(@user1).should == 0
    end

    it "should not reset the player's skip count if :skipping param is passed as true" do
      @game.increment_player_skip_count(@user1)
      @game.save
      @game.reload.player_skip_count(@user1).should == 1

      EndTurn.new(@game, @user1, skipping: true).execute!

      @game.reload.player_skip_count(@user1).should == 1
    end

    describe 'marking players as defeated' do
      it "should mark users lacking both units and unoccupied bases as defeated (one player)" do
        @defeat_user3[]
        EndTurn.new(@game, @user1).execute!

        @game.defeated_players.should include(@user3._id)
        @game.defeated_players.size.should == 1
      end

      it "should mark users lacking both units and unoccupied bases as defeated (two players)" do
        @defeat_user2[]
        @defeat_user3[]
        EndTurn.new(@game, @user1).execute!

        @game.defeated_players.should include(@user2._id, @user3._id)
        @game.defeated_players.size.should == 2
      end

      it "should mark the user as defeated if surrender option is passed" do
        EndTurn.new(@game, @user1, :surrender => true).execute!

        @game.defeated_players.should include(@user1._id)
        @game.defeated_players.size.should == 1
      end

      it "should update the Elo ranking of players if players are defeated (1v1)" do
        @game.defeated_players << @user2._id
        @defeat_user3[]

        elo_mock = mock('elo')
        EloCalculator.should_receive(:new).with([@user3], [@user1]).and_return(elo_mock)
        elo_mock.should_receive(:calculate!)

        EndTurn.new(@game, @user1).execute!
      end

      it "should update the Elo ranking of players if players are defeated (1v2)" do
        @defeat_user3[]

        elo_mock = mock('elo')
        EloCalculator.should_receive(:new).with([@user3], [@user1, @user2]).and_return(elo_mock)
        elo_mock.should_receive(:calculate!)

        EndTurn.new(@game, @user1).execute!
      end

      it "should update the Elo ranking of players if players are defeated (2v1)" do
        @defeat_user2[]
        @defeat_user3[]

        elo_mock = mock('elo')
        EloCalculator.should_receive(:new).with([@user2, @user3], [@user1]).and_return(elo_mock)
        elo_mock.should_receive(:calculate!)

        EndTurn.new(@game, @user1).execute!
      end

      it "should email players who are defeated who are subscribed to the game" do
        @game.defeated_players << @user3._id
        @defeat_user2[]

        mail = mock('mail')
        mail.should_receive(:deliver).once
        UserMailer.should_receive(:defeated).once.with(@game, @user2).and_return(mail)

        EndTurn.new(@game, @user1).execute!
      end

      it "should not email defeated players who are not subscribed to the game" do
        @game.player_subscriptions[2] = false
        @defeat_user3[]
        UserMailer.should_receive(:defeated).never
        EndTurn.new(@game, @user1).execute!
      end

      it "should unsubscribe players who are defeated" do
        @defeat_user2[]

        mail = mock('mail')
        mail.should_receive(:deliver).once
        UserMailer.should_receive(:defeated).once.with(@game, @user2).and_return(mail)

        EndTurn.new(@game, @user1).execute!

        @game.reload.player_subscriptions[1].should == false
        @game.status.should == 'started'
      end

      it "should not doubly-defeat players who were already defeated" do
        @defeat_user2[]

        EndTurn.new(@game, @user1).execute!
        @game.current_user.should == @user3

        UserMailer.should_receive(:defeated).never
        EloCalculator.should_receive(:new).never

        EndTurn.new(@game, @user3).execute!
        EndTurn.new(@game, @user1).execute!
      end
    end

    describe 'ending the game' do
      it "should set status to 'win' if only one player is left undefeated" do
        @defeat_user2[]
        @defeat_user3[]
        EndTurn.new(@game, @user1).execute!
        @game.status.should == 'win'
      end

      it "should not set status to 'win' if there is only one player but no current player" do
        # This happens when a game has just started and no others have joined yet
        game = Game.create(:name => 'test2', :map => Fabricate(:basic_1v1v1_map), :time_limit => 1.hour)
        game.add_player!(@user1)
        EndTurn.new(game, @user1).execute!

        game.status.should == 'started'
        game.winner.should be_nil
      end

      it "should set #winner to the winner's #_id" do
        @defeat_user2[]
        @defeat_user3[]
        EndTurn.new(@game, @user1).execute!
        @game.winner.should == @user1._id.to_s
      end

      it "should email players who won if they are subscribed" do
        @defeat_user2[]
        @defeat_user3[]

        mail = mock('mail')
        mail.should_receive(:deliver).once
        UserMailer.should_receive(:won).once.with(@game, @user1).and_return(mail)

        EndTurn.new(@game, @user1).execute!
      end

      it "should not email players who won if they are not subscribed" do
        @defeat_user2[]
        @defeat_user3[]
        @game.update_player_subscription(@user1, false)
        UserMailer.should_receive(:won).never
        EndTurn.new(@game, @user1).execute!
      end

      it "should set status to 'draw' if all players are defeated" do
        @game.defeated_players << @user1._id
        @defeat_user2[]
        @defeat_user3[]
        EndTurn.new(@game, @user1).execute!
        @game.status.should == 'draw'
      end

      it "should set status to 'draw' if all players either offered peace or are defeated" do
        @game.update_player_peace_offer(@user1, true)
        @game.update_player_peace_offer(@user2, true)
        @game.defeated_players << @user3._id
        EndTurn.new(@game, @user1).execute!
        @game.status.should == 'draw'
      end

      it "should email players who had a draw who are subscribed" do
        @game.defeated_players << @user1._id
        @defeat_user2[]
        @defeat_user3[]

        mail1 = mock('mail1')
        mail1.should_receive(:deliver).once
        UserMailer.should_receive(:draw).with(@game, @user2).once.and_return(mail1)

        mail2 = mock('mail2')
        mail2.should_receive(:deliver).once
        UserMailer.should_receive(:draw).with(@game, @user3).once.and_return(mail2)

        EndTurn.new(@game, @user1).execute!
      end

      it "should not email players who had a draw who are not subscribed" do
        @game.update_player_subscription(@user2, false)
        @game.defeated_players << @user1._id
        @defeat_user2[]
        @defeat_user3[]

        UserMailer.should_receive(:draw).with(@game, @user2).never

        mail = mock('mail')
        mail.should_receive(:deliver).once
        UserMailer.should_receive(:draw).with(@game, @user3).and_return(mail)

        EndTurn.new(@game, @user1).execute!
      end
      
      it "should not calculate Elo for a draw" do
        @game.defeated_players << @user1._id
        @defeat_user2[]
        @defeat_user3[]
        EloCalculator.should_receive(:new).never
        EndTurn.new(@game, @user1).execute!
      end
    end

    describe 'resetting units' do
      before do
        @cap_unit = @add_unit[7, 10]
        @cap_unit.moved = true

        @game.base_at(7, 10).start_capture(@user1._id.to_s, 1)

        @build_unit = @add_unit[8, 8]
        @build_unit.moved = true
        @build_unit.build_phase = 1
        @build_unit.current_build = :road

        @game.units.each do |u|
          u.flank_penalty = 2
          u.attacks = 2
          u.attacked = true
          u.healed = true
          u.movement_points = 0
          u.summoning_sickness = true
        end
      end

      it "should reset the flank_penalty and summoning_sickness of all units" do
        EndTurn.new(@game, @user1).execute!

        @game.units.each do |u|
          u.flank_penalty.should == 0
          u.summoning_sickness.should == false
        end
      end

      it "should reset the movement_points, attacks, attacked flag, healed flag, and moved flag of all units except those capturing or building" do
        EndTurn.new(@game, @user1).execute!

        @game.units.each do |u|
          if u == @cap_unit or u == @build_unit
            u.movement_points.should == 0
            u.attacks.should == 2
            u.attacked.should be_true
            u.healed.should be_true
            u.moved.should be_true
          else
            u.movement_points.should == 9
            u.attacks.should == 0
            u.attacked.should be_false
            u.healed.should be_false
            u.moved.should be_false
          end
        end
      end

      it "should reset the flank_penalty, movement_points, attacks, and moved flag of loaded units" do
        @game.units.last.loaded_units << Unit.new(:Infantry, 1, 1, 1)
        @game.units.last.loaded_units.last.movement_points = 0
        @game.units.last.loaded_units.last.attacks = 1
        @game.units.last.loaded_units.last.flank_penalty = 1
        @game.units.last.loaded_units.last.moved = true
        @game.units.last.loaded_units << Unit.new(:Infantry, 1, 1, 1)
        @game.units.last.loaded_units.last.movement_points = 0
        @game.units.last.loaded_units.last.attacks = 1
        @game.units.last.loaded_units.last.flank_penalty = 1
        @game.units.last.loaded_units.last.moved = true

        EndTurn.new(@game, @user1).execute!

        @game.units.last.loaded_units[0].movement_points.should == 9
        @game.units.last.loaded_units[0].attacks.should == 0
        @game.units.last.loaded_units[0].flank_penalty.should == 0
        @game.units.last.loaded_units[0].moved.should == false
        @game.units.last.loaded_units[1].movement_points.should == 9
        @game.units.last.loaded_units[1].attacks.should == 0
        @game.units.last.loaded_units[1].flank_penalty.should == 0
        @game.units.last.loaded_units[1].moved.should == false
      end

      it "should remove air units which are parked over enemy bases" do
        @add_unit[11, 10, @user1, :Fighter]
        @game.unit_at(11, 10).should_not be_nil

        EndTurn.new(@game, @user1).execute!

        @game.reload.unit_at(11, 10).should be_nil
      end

      it "should not remove air units which are parked over friendly bases" do
        @add_unit[6, 7, @user1, :Fighter]
        @game.unit_at(6, 7).should_not be_nil

        EndTurn.new(@game, @user1).execute!

        @game.reload.unit_at(6, 7).should_not be_nil
      end

      it "should not remove air units which are parked over neutral bases" do
        @add_unit[7, 5, @user1, :Fighter]
        @game.unit_at(7, 5).should_not be_nil

        EndTurn.new(@game, @user1).execute!

        @game.reload.unit_at(7, 5).should_not be_nil
      end
    end

    describe 'advancing to the next turn' do
      it "should advance the turn to the next player" do
        EndTurn.new(@game, @user1).execute!
        @game.current_user.should == @user2
        @game.turns_played.should == 1
        @game.rounds_played.should == 0
      end

      it "should skip defeated players" do
        @game.defeated_players << @user2._id
        EndTurn.new(@game, @user1).execute!
        @game.current_user.should == @user3
        @game.turns_played.should == 2
        @game.rounds_played.should == 0
      end

      it "should loop back around to the first player after the last player ends their turn" do
        EndTurn.new(@game, @user1).execute!
        EndTurn.new(@game, @user2).execute!
        EndTurn.new(@game, @user3).execute!
        @game.current_user.should == @user1
        @game.turns_played.should == 3
        @game.rounds_played.should == 1
      end

      it "should loop back around to the first player after the last player is skipped as defeated" do
        @game.defeated_players << @user3._id
        EndTurn.new(@game, @user1).execute!
        EndTurn.new(@game, @user2).execute!
        @game.current_user.should == @user1
        @game.turns_played.should == 3
        @game.rounds_played.should == 1
      end

      it "should wait for another player if there is no player for the new turn" do
        @game2 = Game.create(:name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour)
        @game2.add_player!(@user1)
        EndTurn.new(@game2, @user1).execute!
        @game2.current_user.should be_nil
        @game2.turns_played.should == 1
        @game2.rounds_played.should == 0
      end
    end

    describe "starting the next player's turn" do
      it "should grant the new player credits according to the bases they possess (not counting bases which will be acquired this turn)" do
        @game.reload.player_credits[0].should == 600
        EndTurn.new(@game, @user1).execute!
        @game.reload.player_credits[1].should == 400
        EndTurn.new(@game, @user2).execute!
        @game.reload.player_credits[2].should == 200
        EndTurn.new(@game, @user3).execute!
        @game.reload.player_credits[0].should == 1200
      end
      
      it "should grant the new player credits even if they have not yet joined the game" do
        @game2 = Game.create(:name => 'test', :map => Fabricate(:basic_1v1v1_map), :time_limit => 1.hour)
        @game2.add_player!(@user1)
        EndTurn.new(@game2, @user1).execute!
        @game2.player_credits[1].should == 400
      end

      it "should continue the capturing phases of each base the new player is capturing" do
        @add_unit[7, 5, @user2]
        @game.base_at(7, 5).start_capture(@user2._id.to_s, 2)

        @add_unit[6, 7, @user2]
        @game.base_at(6, 7).start_capture(@user2._id.to_s, 2)

        @add_unit[13, 9]
        @game.base_at(13, 9).start_capture(@user1._id.to_s, 1)

        EndTurn.new(@game, @user1).execute

        @game.base_at(7, 5).capture_phase.should == 0
        @game.base_at(7, 5).capture_player_id.should == @user2._id.to_s
        @game.base_at(7, 5).capture_player.should == 2

        @game.base_at(6, 7).capture_phase.should == 0
        @game.base_at(6, 7).capture_player_id.should == @user2._id.to_s
        @game.base_at(6, 7).capture_player.should == 2

        @game.base_at(13, 9).capture_phase.should == 1
        @game.base_at(13, 9).capture_player_id.should == @user1._id.to_s
        @game.base_at(13, 9).capture_player.should == 1

        @game.base_at(9, 13).capture_phase.should be_nil
        @game.base_at(9, 13).capture_player_id.should be_nil
        @game.base_at(9, 13).capture_player.should be_nil
      end

      it "should complete capture and remove capturing unit of any bases finished capturing for the new player" do
        @add_unit[7, 5, @user2]
        @game.base_at(7, 5).start_capture(@user2._id.to_s, 2)
        @game.base_at(7, 5).continue_capture
        @add_unit[6, 7, @user2]
        @game.base_at(6, 7).start_capture(@user2._id.to_s, 2)
        @game.base_at(6, 7).continue_capture

        @add_unit[7, 10]
        @game.base_at(7, 10).start_capture(@user2._id.to_s, 2)

        EndTurn.new(@game, @user1).execute

        @game.base_at(7, 5).capture_phase.should be_nil
        @game.base_at(7, 5).player_id.should == @user2._id.to_s
        @game.unit_at(7, 5).should be_nil

        @game.base_at(6, 7).capture_phase.should be_nil
        @game.base_at(6, 7).player_id.should == @user2._id.to_s
        @game.unit_at(6, 7).should be_nil

        @game.base_at(7, 10).capture_phase.should_not be_nil
        @game.unit_at(7, 10).should_not be_nil
      end

      it "should continue, completing if necessary, the build phases of each unit the new player is building with" do
        u = @add_unit[8, 8, @user2]
        u.build_phase = 0; u.current_build = :road

        u = @add_unit[11, 8, @user2]
        u.build_phase = 1; u.current_build = :road

        u = @add_unit[9, 11, @user1]
        u.build_phase = 1; u.current_build = :road

        EndTurn.new(@game, @user1).execute

        @game.unit_at(8, 8).build_phase.should == nil
        @game.unit_at(8, 8).current_build.should == nil
        @game.unit_at(8, 8).movement_points.should == 9
        @game.unit_at(8, 8).attacks.should == 0
        @game.unit_at(8, 8).moved.should == false
        @game.terrain_at(8, 8).should == :road

        @game.unit_at(11, 8).build_phase.should == 0
        @game.unit_at(11, 8).current_build.should == :road
        @game.terrain_at(11, 8).should == :plains

        @game.unit_at(9, 11).build_phase.should == 1
        @game.unit_at(9, 11).current_build.should == :road
        @game.terrain_at(9, 11).should == :plains
      end

      it "should allow properly destroy improvements if that is a unit's completed build" do
        @game.terrain_modifiers << TerrainModifier.new(:road, 8, 8)
        @game.terrain_at(8, 8).should == :road

        u = @add_unit[8, 8, @user2]
        u.build_phase = 0; u.current_build = :destroy

        EndTurn.new(@game, @user1).execute

        @game.unit_at(8, 8).build_phase.should == nil
        @game.unit_at(8, 8).current_build.should == nil
        @game.unit_at(8, 8).movement_points.should == 9
        @game.unit_at(8, 8).attacks.should == 0
        @game.unit_at(8, 8).moved.should == false
        @game.terrain_at(8, 8).should == :plains
      end

      it "should update #turn_started_at to the current time" do
        now = Time.now + 5.minutes
        Time.stub(:now => now)

        EndTurn.new(@game, @user1).execute

        @game.turn_started_at.to_i.should == now.to_i
      end

      it "should email the player whose turn it is if they exist and if they are subscribed" do
        mail = mock('mail')
        mail.should_receive(:deliver).once
        UserMailer.should_receive(:new_turn).with(@game, @user2).once.and_return(mail)

        EndTurn.new(@game, @user1).execute
      end

      it "should not email the player whose turn it is if they are not subscribed" do
        @game.update_player_subscription(@user2, false)
        UserMailer.should_receive(:new_turn).with(@game, @user2).never
        EndTurn.new(@game, @user1).execute
      end

      it "should not email the player whose turn it is if the game is concluded" do
        @defeat_user2[]
        @defeat_user3[]
        UserMailer.should_receive(:new_turn).with(@game, @user2).never
        EndTurn.new(@game, @user1).execute
      end
    end
  end

  describe "#unexecute" do
    it "should raise IrreversibleCommand" do
      lambda do
        EndTurn.new(@game, @user1).unexecute
      end.should raise_error(IrreversibleCommand)
    end
  end
end
