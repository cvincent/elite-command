require 'spec_helper'

describe CaptureBase do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @game.units << Unit.new(:Infantry, 1, 5, 5)
    @game.units << Unit.new(:Tank, 1, 8, 11)
    @game.add_player!(@user1)
    @game.add_player!(@user2)

    @call_expecting_error = ->(x, y, err, u = @user1) {
      lambda do
        CaptureBase.new(@game, u, :x => x, :y => y).execute!
      end.should raise_error(CommandError, err)
    }

    @add_unit = ->(unit_type, x, y, player = 1) {
      @game.units << Unit.new(unit_type, player, x, y)
      @game.units.last.player_id = @game.players[player - 1].try(:to_s) || nil
    }
  end

  describe '#execute!' do
    it 'should fail if the acting user is not the current player' do
      @call_expecting_error[5, 5, "Not user's turn.", @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(:status => 'win')
      @call_expecting_error[5, 5, "Game not running."]
    end

    it 'should fail if x and y does not get an actual base' do
      @call_expecting_error[8, 4, "No such base."]
    end

    it 'should fail if x and y does not get a base not owned by the player' do
      @add_unit[:Infantry, 8, 3]
      @call_expecting_error[8, 3, "Targeted base is friendly."]
    end

    it 'should fail if x and y does not get an actual unit' do
      @call_expecting_error[5, 9, "No such unit."]
    end

    it 'should fail if x and y does not get a unit owned by the player' do
      @add_unit[:Infantry, 11, 9, 2]
      @call_expecting_error[11, 9, "Not user's unit."]
    end

    it 'should fail if x and y does not get a unit which can capture bases' do
      @call_expecting_error[8, 11, "Unit cannot capture."]
    end

    it "should begin the base's capture phases" do
      CaptureBase.new(@game, @user1, :x => 5, :y => 5).execute

      @game.base_at(5, 5).capture_player_id.should == @user1._id.to_s
      @game.base_at(5, 5).capture_player.should == 1
      @game.base_at(5, 5).capture_phase.should == 1

      @add_unit[:Infantry, 11, 5, 1]
      CaptureBase.new(@game, @user1, :x => 11, :y => 5).execute

      @game.base_at(11, 5).capture_player_id.should == @user1._id.to_s
      @game.base_at(11, 5).capture_player.should == 1
      @game.base_at(11, 5).capture_phase.should == 1
    end
  end

  describe '#unexecute!' do
    it "should reset the base's capture variables" do
      cb = CaptureBase.new(@game, @user1, :x => 5, :y => 5)
      cb.execute
      cb.unexecute

      @game.base_at(5, 5).capture_player_id.should be_nil
      @game.base_at(5, 5).capture_player.should be_nil
      @game.base_at(5, 5).capture_phase.should be_nil
    end
  end
end
