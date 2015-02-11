require 'spec_helper'

describe GameCommand do
  before do
    @user = Fabricate(:user)
    @game = Game.create(:name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour)
    @game.add_player!(@user)
  end

  describe 'subclasses' do
    before do
      GameCommandTestSubclass ||= Class.new(GameCommand) do
        def execute
          { :param1 => '1' }
        end

        def unexecute
          { :param2 => '2' }
        end
      end

      @command = GameCommandTestSubclass.new(@game, @user)
    end

    describe '#execute!' do
      it 'should call #execute and then save the given game' do
        @command.should_receive(:execute)
        @game.should_receive(:save)

        @command.execute!
      end

      it 'should return the return of #execute' do
        @command.execute!.should == { :param1 => '1' }
      end
    end

    describe '#unexecute!' do
      it 'should call #unexecute and then save the given game' do
        @command.should_receive(:unexecute)
        @game.should_receive(:save)

        @command.unexecute!
      end

      it 'should return the return of #unexecute' do
        @command.unexecute.should == { :param2 => '2' }
      end
    end

    describe 'un/marshalling' do
      it "should marshal and unmarshal while keeping the @game and @user intact" do
        dumped = Marshal.dump(@command)

        # Cheap way of making sure that the serialized object is small; should only serialize
        # the game and user #_ids, rather than the full objects
        dumped.length.should <= 200

        loaded = Marshal.load(dumped)
        loaded.instance_variable_get(:@game).should == @game
        loaded.instance_variable_get(:@user).should == @user
      end
    end
  end

  describe '#modify and #modify_game' do
    before do
      GameCommandModifyTest ||= Class.new(GameCommand) do
        def execute
          @unit = @game.unit_at(8, 4)
          @base = @game.base_at(11, 5)

          modify(@unit, :health, 7)
          modify(@unit, :movement_points, 3)
          modify(@base, :player_id, @user.id.to_s)
          modify(@base, :player, 1)
          modify_game(:turns_played, 56)
          modify_game(:status, 'blah')
        end
      end

      @modify = GameCommandModifyTest.new(@game, @user)
    end

    it 'should allow discrete changes to game and game objects' do
      @modify.execute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).health.should == 7
      @game.unit_at(8, 4).movement_points.should == 3
      @game.base_at(11, 5).player_id.should == @user.id.to_s
      @game.base_at(11, 5).player.should == 1
      @game.turns_played.should == 56
      @game.status.should == 'blah'
    end

    it 'should allow reversible changes to game and game objects' do
      @modify.execute!
      @modify.unexecute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).health.should == 10
      @game.unit_at(8, 4).movement_points.should == 9
      @game.base_at(11, 5).player_id.should be_nil
      @game.base_at(11, 5).player.should == 2
      @game.turns_played.should == 0
      @game.status.should == 'started'
    end

    it 'should persist changes through un/marshalling' do
      @modify.execute!
      dump = Marshal.dump(@modify)
      Marshal.load(dump).unexecute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).health.should == 10
      @game.unit_at(8, 4).movement_points.should == 9
      @game.base_at(11, 5).player_id.should be_nil
      @game.base_at(11, 5).player.should == 2
      @game.turns_played.should == 0
      @game.status.should == 'started'
    end
  end

  describe '#modify_credits' do
    before do
      GameCommandModifyCreditsTest ||= Class.new(GameCommand) do
        def execute
          modify_credits(1, 987)
        end
      end

      @modify = GameCommandModifyCreditsTest.new(@game, @user)
    end

    it "should set a given player's credits" do
      @modify.execute!

      @game = Game.find(@game.id)
      @game.user_credits(@user).should == 987
    end

    it "should be reversible" do
      @modify.execute!
      @modify.unexecute!

      @game = Game.find(@game.id)
      @game.user_credits(@user).should == 200
    end

    it "should persist changes through un/marshalling" do
      @modify.execute!
      dump = Marshal.dump(@modify)
      Marshal.load(dump).unexecute!

      @game = Game.find(@game.id)
      @game.user_credits(@user).should == 200
    end
  end

  describe '#create_unit' do
    before do
      GameCommandCreateUnitTest ||= Class.new(GameCommand) do
        def execute
          create_unit(@user, :Sniper, 8, 7)
        end
      end

      @modify = GameCommandCreateUnitTest.new(@game, @user)
    end

    it "should add units to the game" do
      @modify.execute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 7).should_not be_nil
      @game.unit_at(8, 7).unit_type.should == :Sniper
      @game.unit_at(8, 7).player.should == 1
    end

    it "should be reversible" do
      @modify.execute!
      @modify.unexecute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 7).should be_nil
    end

    it "should persist changes through un/marshalling" do
      @modify.execute!
      dump = Marshal.dump(@modify)
      Marshal.load(dump).unexecute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 7).should be_nil
    end
  end

  describe '#destroy_unit' do
    before do
      GameCommandDestroyUnitTest ||= Class.new(GameCommand) do
        def execute
          destroy_unit(@game.unit_at(8, 4))
        end
      end

      @modify = GameCommandDestroyUnitTest.new(@game, @user)
    end

    it "should remove units from the game" do
      @modify.execute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).should be_nil
    end

    it "should be reversible" do
      @modify.execute!
      @modify.unexecute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).should_not be_nil
      @game.unit_at(8, 4).movement_points.should == 9
      @game.unit_at(8, 4).health.should == 10
    end

    it "should persist changes through un/marshalling" do
      @modify.execute!
      dump = Marshal.dump(@modify)
      Marshal.load(dump).unexecute!

      @game = Game.find(@game.id)
      @game.unit_at(8, 4).should_not be_nil
      @game.unit_at(8, 4).movement_points.should == 9
      @game.unit_at(8, 4).health.should == 10
    end
  end

  describe '#modify_skip_count' do
    before do
      GameCommandModifySkipCountTest ||= Class.new(GameCommand) do
        def execute
          modify_skip_count(@user, 1)
        end
      end

      @modify = GameCommandModifySkipCountTest.new(@game, @user)
    end

    it "should change the skip count for the player" do
      @modify.execute!

      @game = Game.find(@game.id)
      @game.player_skip_count(@user).should == 1
    end

    it "should be reversible" do
      @modify.execute!
      dump = Marshal.dump(@modify)
      Marshal.load(dump).unexecute!

      @game = Game.find(@game.id)
      @game.player_skip_count(@user).should == 0
    end
  end
end
