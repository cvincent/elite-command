require 'spec_helper'

describe Base do
  before do
    @b = Base.new(:Base, 0, 5, 5, nil)
  end

  it 'should instantiate with base_type, player, x, y, capture_phase, and capture_player_id' do
    Base.new(:Base, 0, 10, 10, nil, nil).should be_a(Base)
  end

  it 'should default to no capture phase and no capture player' do
    b = Base.new(:Base, 0, 10, 10)
    b.capture_phase.should be_nil
    b.capture_player_id.should be_nil
  end

  it 'should not be equal to another base with the same attributes' do
    b1 = Base.new(:Base, 0, 10, 10, nil)
    b2 = Base.new(:Base, 0, 10, 10, nil)
    b1.should_not == b2

    b2 = b1.dup
    b1.should_not == b2
  end

  it 'should allow access to #player_id' do
    @b.player_id.should == nil
    @b.player_id = 'asdf'
    @b.player_id.should == 'asdf'
  end

  describe '#unit_types' do
    it 'should return the units which the base is capable of building' do
      @b.unit_types.should include(:Infantry, :Tank, :HeavyTank)
      @b.unit_types.should_not include(:Fighter)
    end
  end

  describe '#can_build_unit_type?(unit_type)' do
    it 'should return false for a unit_type the base cannot build' do
      @b.can_build_unit_type?(:Fighter).should == false
    end

    it 'should return true for a unit_type the base can build' do
      @b.can_build_unit_type?(:Infantry).should == true
    end
  end

  describe '#build_unit_type(unit_type)' do
    it 'should return a new Unit of the proper type at the same location as the Base' do
      @b.player_id = 'asdf'

      u = @b.build_unit_type(:Infantry)
      u.should be_a(Unit)
      u.unit_type.should == :Infantry
      u.player.should == 0
      u.player_id.should == 'asdf'
      u.x.should == @b.x
      u.y.should == @b.y
    end

    it 'should a new Unit which is unable to move or attack' do
      @b.player_id = 'asdf'

      u = @b.build_unit_type(:Humvee)
      u.has_enough_attack_points_to_attack?.should == false
      u.movement_points.should == 0
    end
  end

  describe '#start_capture(capture_player_id, capture_player)' do
    it 'should set #capture_phase to 1 and and capture_player_id to the givens' do
      @b.start_capture('qwer', 2)
      @b.capture_phase.should == 1
      @b.capture_player_id.should == 'qwer'
      @b.capture_player.should == 2
    end
  end

  describe '#continue_capture' do
    it 'should subtract 1 from capture phase' do
      @b.start_capture('qwer', 2)
      @b.continue_capture
      @b.capture_phase.should == 0
    end

    it 'should return false if the base is not finished capturing' do
      @b.start_capture('qwer', 2)
      @b.continue_capture.should == false
      @b.player_id.should == nil
      @b.player.should_not == 2
    end

    it 'should set the new player and player_id and reset capture attributes if the base is finished capturing' do
      @b.start_capture('qwer', 2)
      @b.continue_capture.should == false
      @b.continue_capture.should == true
      @b.player_id.should == 'qwer'
      @b.player.should == 2
      @b.capture_phase.should be_nil
      @b.capture_player_id.should be_nil
      @b.capture_player.should be_nil
    end
  end

  describe '#cancel_capture' do
    it 'should reset all capture variables' do
      @b.start_capture('qwer', 2)
      @b.cancel_capture
      @b.player_id.should be_nil
      @b.capture_phase.should be_nil
      @b.capture_player_id.should be_nil
      @b.capture_player.should be_nil
    end
  end
end
