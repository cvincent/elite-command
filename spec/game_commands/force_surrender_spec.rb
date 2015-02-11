require 'spec_helper'

describe ForceSurrender do
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
        ForceSurrender.new(@game, @user3).execute!
      end.should raise_error(CommandError, "User is not in the game.")
    end

    it "should fail if the game is waiting for a player to enter" do
      @game2 = Game.create(
        :name => 'test2', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
      )
      @game2.add_player!(@user1)
      
      EndTurn.new(@game2, @user1).execute!

      lambda do
        ForceSurrender.new(@game2, @user1).execute!
      end.should raise_error(CommandError, "Waiting for a player to enter the game.")
    end

    it "should fail if the current player has not been skipped twice consecutively" do
      EndTurn.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      SkipPlayer.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      # @user2 has been skipped once and is over time

      lambda do
        ForceSurrender.new(@game, @user1).execute!
      end.should raise_error(CommandError, "Current player has not been skipped twice consecutively.")
    end

    it "should fail if the current player has not exceeded the time limit" do
      EndTurn.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      SkipPlayer.new(@game, @user1).execute!
      EndTurn.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      SkipPlayer.new(@game, @user1).execute!
      EndTurn.new(@game, @user1).execute!
      # @user2 has been skipped twice consecutively but is not over time

      lambda do
        ForceSurrender.new(@game, @user1).execute!
      end.should raise_error(CommandError, "Current player has not exceeded time limit.")
    end

    it "should surrender the current player as though they had done it themselves" do
      EndTurn.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      SkipPlayer.new(@game, @user1).execute!
      EndTurn.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      SkipPlayer.new(@game, @user1).execute!
      EndTurn.new(@game, @user1).execute!
      @game.turn_started_at = Time.now - 60.minutes
      # @user2 has been skipped twice consecutively and is over time

      ForceSurrender.new(@game, @user1).execute!

      @game.reload.status.should == 'win'
      @game.winner.should == @user1._id.to_s
    end
  end
end
