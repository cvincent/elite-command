require 'spec_helper'

describe SkipPlayer do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @user3 = Fabricate(:user)

    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )

    @game.add_player!(@user1)
    @game.add_player!(@user2)
  end

  describe '#execute' do
    it "should fail if the user isn't a player in the game" do
      lambda do
        SkipPlayer.new(@game, @user3).execute!
      end.should raise_error(CommandError, "User is not in the game.")
    end

    it "should fail if the game is waiting for a player to enter" do
      @game2 = Game.create(
        :name => 'test2', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
      )
      @game2.add_player!(@user1)
      
      EndTurn.new(@game2, @user1).execute!

      lambda do
        SkipPlayer.new(@game2, @user1).execute!
      end.should raise_error(CommandError, "Waiting for a player to enter the game.")
    end

    it "should fail if the current player has not exceed the time limit" do
      @game.turn_started_at = Time.now - 55.minutes

      lambda do
        SkipPlayer.new(@game, @user2).execute!
      end.should raise_error(CommandError, "Current player has not exceeded time limit.")
    end

    it "should skip the current player's turn as though the player ended their turn" do
      @game.turn_started_at = Time.now - 60.minutes

      SkipPlayer.new(@game, @user2).execute!

      @game.current_user.should == @user2
      @game.turn_started_at.should > Time.now - 60.minutes
    end

    it "should increment the skipped player's consecutive skip count" do
      @game.turn_started_at = Time.now - 60.minutes
      SkipPlayer.new(@game, @user2).execute!
      @game.reload.player_skip_count(@user1).should == 1
    end
  end

  describe "#unexecute" do
    it "should raise IrreversibleCommand" do
      lambda do
        SkipPlayer.new(@game, @user2).unexecute!
      end.should raise_error(IrreversibleCommand)
    end
  end
end
