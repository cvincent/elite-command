require 'spec_helper'

describe BeginBuilding do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
    @game = Game.create(
      :name => 'test', :map => Fabricate(:buildings_spec_map), :time_limit => 1.hour
    )
    @game.units << Unit.new(:Infantry, 1, 5, 5)
    @game.units << Unit.new(:Tank, 1, 8, 11)
    @game.add_player!(@user1)
    @game.add_player!(@user2)

    @call_expecting_error = ->(x, y, building, err, u = @user1) {
      lambda do
        BeginBuilding.new(@game, u, x: x, y: y, building: building).execute!
      end.should raise_error(CommandError, err)
    }

    @add_unit = ->(unit_type, x, y, player = 1) {
      @game.units << Unit.new(unit_type, player, x, y)
      @game.units.last.player_id = @game.players[player - 1].try(:to_s) || nil
    }
  end

  describe "#execute!" do
    it "should fail if the acting user is not the current player" do
      @call_expecting_error[8, 9, 'bridge', "Not user's turn.", @user2]
    end

    it "should fail if the game is concluded" do
      @game.update_attributes(status: 'win')
      @call_expecting_error[8, 9, 'bridge', "Game not running."]
    end

    it "should fail if x and y does not get an actual unit" do
      @call_expecting_error[8, 8, 'bridge', "No such unit."]
    end

    it "should fail if x and y does not get a unit owned by the player" do
      @add_unit[:Engineer, 9, 11, 2]
      @call_expecting_error[9, 11, 'bridge', "Not user's unit."]
    end

    it "should fail if the unit is unable to build the building" do
      @add_unit[:Ranger, 9, 11]
      @call_expecting_error[9, 11, 'bridge', "Unit can't build that."]
    end

    it "should fail if the player can't afford the building" do
      @game.set_user_credits(@user1, 50)
      @call_expecting_error[8, 9, 'bridge', "Not enough credits."]
    end

    it "should deduct the unit's cost for that building from the player's credits" do
      @game.set_user_credits(@user1, 150)
      BeginBuilding.new(@game, @user1, x: 8, y: 9, building: 'bridge').execute!
      @game.user_credits(@user1).should == 50
    end

    it "should set the unit's current_build to the building" do
      BeginBuilding.new(@game, @user1, x: 8, y: 9, building: 'bridge').execute!
      @game.reload.unit_at(8, 9).current_build.should == :bridge
    end

    it "should set the unit's build_phase according to the unit's build time for that building" do
      BeginBuilding.new(@game, @user1, x: 8, y: 9, building: 'bridge').execute!
      @game.reload.unit_at(8, 9).build_phase.should == 0
    end

    it "should should take away the unit's remaining movement points and attacks" do
      BeginBuilding.new(@game, @user1, x: 8, y: 9, building: 'bridge').execute!
      @game.reload.unit_at(8, 9).attacks.should == 1
      @game.unit_at(8, 9).movement_points.should == 0
    end

    describe "clear woods" do
      it "should fail if x and y is not woods" do
        @call_expecting_error[13, 12, 'plains', "No woods to clear."]
      end

      it "should succeed if x and y is woods" do
        lambda do
          BeginBuilding.new(@game, @user1, x: 14, y: 13, building: 'plains').execute!
        end.should_not raise_error
      end
    end

    describe "build road" do
      it "should fail if the unit is not on plains, desert, or tundra" do
        @call_expecting_error[11, 1, 'road', "Cannot build road there."]
      end

      it "should succeed if the unit is on plains" do
        lambda do
          BeginBuilding.new(@game, @user1, x: 13, y: 12, building: 'road').execute!
        end.should_not raise_error
      end

      it "should succeed if the unit is on desert" do
        lambda do
          BeginBuilding.new(@game, @user1, x: 9, y: 13, building: 'road').execute!
        end.should_not raise_error
      end

      it "should succeed if the unit is on tundra" do
        lambda do
          BeginBuilding.new(@game, @user1, x: 9, y: 0, building: 'road').execute!
        end.should_not raise_error
      end

      it "should succeed if the unit is on plains resulting from cleared woods" do
        @game.terrain_modifiers << TerrainModifier.new(:plains, 14, 13)
        lambda do
          BeginBuilding.new(@game, @user1, x: 14, y: 13, building: 'road').execute!
        end.should_not raise_error
      end
    end

    describe "build bridge" do
      it "should fail if the unit is not on shallow water or ford" do
        @call_expecting_error[2, 2, 'bridge', "Cannot build bridge there."]
      end

      it "should fail if the unit is surrounded by water" do
        @call_expecting_error[9, 16, 'bridge', "Cannot build bridge there."]
      end

      it "should fail if the tile can only connect swamp" do
        @call_expecting_error[4, 6, 'bridge', "Cannot build bridge there."]
      end

      it "should fail if the tile cannot connect two sides" do
        @call_expecting_error[9, 15, 'bridge', "Cannot build bridge there."]
      end

      it "should succeed for a bridgeable tile" do
        @game.terrain_modifiers << TerrainModifier.new(:plains, 14, 13)
        lambda do
          BeginBuilding.new(@game, @user1, x: 8, y: 9, building: 'bridge').execute!
        end.should_not raise_error
      end
    end

    describe "destroy improvement" do
      it "should fail if the unit is not on a road or bridge" do
        @call_expecting_error[9, 13, 'destroy', "Nothing to destroy."]
      end

      it "should fail if the unit is on cleared woods" do
        @game.terrain_modifiers << TerrainModifier.new(:plains, 14, 13)
        @call_expecting_error[14, 13, 'destroy', "Nothing to destroy."]
      end

      it "should succeed if the unit is on a road" do
        @game.terrain_modifiers << TerrainModifier.new(:road, 9, 13)
        lambda do
          BeginBuilding.new(@game, @user1, x: 9, y: 13, building: 'destroy').execute!
        end.should_not raise_error
      end

      it "should succeed if the unit is on a bridge" do
        @game.terrain_modifiers << TerrainModifier.new(:bridge, 8, 9)
        lambda do
          BeginBuilding.new(@game, @user1, x: 8, y: 9, building: 'destroy').execute!
        end.should_not raise_error
      end
    end
  end
end
