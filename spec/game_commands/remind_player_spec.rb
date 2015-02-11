require 'spec_helper'

describe RemindPlayer do
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
    it "should fail if acting user is not in the game" do
      lambda do
        RemindPlayer.new(@game, @user3).execute!
      end.should raise_error(CommandError, "User is not in the game.")
    end

    it "should fail if no user has taken the current slot" do
      @game2 = Game.create(
        :name => 'test2', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
      )
      @game2.add_player!(@user1)

      EndTurn.new(@game2, @user1).execute!

      lambda do
        RemindPlayer.new(@game2, @user1).execute!
      end.should raise_error(CommandError, "Waiting for a player to enter the game.")
    end

    it "should fail if Time.now - Game#turn_started_at is less than Game#time_limit" do
      @game.turn_started_at = Time.now - 55.minutes
      @game.reminder_sent_at = nil

      lambda do
        RemindPlayer.new(@game, @user2).execute!
      end.should raise_error(CommandError, "Current player has not exceeded time limit.")
    end

    it "should fail if Time.now - Game#reminder_sent_at is less than Game#time_limit" do
      @game.turn_started_at = Time.now - 120.minutes
      @game.reminder_sent_at = Time.now - 55.minutes

      lambda do
        RemindPlayer.new(@game, @user2).execute!
      end.should raise_error(CommandError, "Cannot send another reminder yet.")
    end

    it "should succeed if Time.now - Game#turn_started_at is greater than
        Game#time_limit, and Game#reminder_sent_at is nil" do

      @game.turn_started_at = Time.now - 120.minutes
      @game.reminder_sent_at = nil

      now = Time.now
      Time.stub(:now => now)

      mail = mock
      mail.should_receive(:deliver).once
      UserMailer.should_receive(:turn_reminder).with(@game, @user2).and_return(mail)

      RemindPlayer.new(@game, @user2).execute!

      @game.reminder_sent_at.to_i.should == now.to_i
    end

    it "should succeed if Time.now - Game#turn_started_at and Time.now - Game#reminder_sent_at
        are greater than Game#time_limit" do

      @game.turn_started_at = Time.now - 120.minutes
      @game.reminder_sent_at = Time.now - 65.minutes

      now = Time.now
      Time.stub(:now => now)

      mail = mock
      mail.should_receive(:deliver).once
      UserMailer.should_receive(:turn_reminder).with(@game, @user2).and_return(mail)

      RemindPlayer.new(@game, @user2).execute!

      @game.reminder_sent_at.to_i.should == now.to_i
    end
  end

  describe '#unexecute' do
    it "should fail with IrreversibleCommand" do
      lambda do
        RemindPlayer.new(@game, @user2).unexecute!
      end.should raise_error(IrreversibleCommand)
    end
  end
end
