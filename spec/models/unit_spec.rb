require 'spec_helper'

describe Unit do
  it 'should instantiate with unit_type, player, x, y, health, movement_points, attacks, and loaded_units' do
    Unit.new(:Infantry, 0, 10, 10, 10, 9, 0, 0, [], false, false).should be_a(Unit)
  end

  it 'should be instantiable from just a unit_type, player, x, and y, with default movement points for the unit_type' do
    u = Unit.new(:Infantry, 0, 10, 10)
    u.player.should == 0
    u.health.should == 10
    u.movement_points.should == UnitDefinitions[:Infantry][:movement_points]
    u.attacks.should == 0
    u.flank_penalty.should == 0
    u.loaded_units.should be_empty
    u.moved.should == true
  end

  it "should allow access to the unit_type's definition's attributes" do
    u = Unit.new(:Infantry, 0, 10, 10)
    u.can_capture.should == UnitDefinitions[:Infantry][:can_capture]
    u.movement[:plains].should == UnitDefinitions[:Infantry][:movement][:plains]
    u.attack_type.should == :move_attack

    lambda do
      u.not_an_attribute
    end.should raise_error(NoMethodError)
  end

  it 'should not be equal to another unit with the same attributes' do
    u1 = Unit.new(:Infantry, 1, 10, 10)
    u2 = Unit.new(:Infantry, 1, 10, 10)
    u1.should_not == u2

    u2 = u1.dup
    u1.should_not == u2
  end

  describe '.price_for_unit_type(unit_type)' do
    it 'should return nil for a non-existant unit_type' do
      Unit.price_for_unit_type(:Bugaboo).should be_nil
    end

    it 'should return the correct price for the unit_type' do
      Unit.price_for_unit_type(:Infantry).should == 75
    end
  end

  describe '#can_attack_unit_type?(unit_type)' do
    it "should return false if the unit_type has an attack of 0 against the given unit's armor_type" do
      Unit.new(:Infantry, 1, 10, 10).can_attack_unit_type?(:Fighter).should == false
    end

    it "should return true if the unit_type has an attack > 0 against the given unit's armor_type" do
      Unit.new(:Infantry, 1, 10, 10).can_attack_unit_type?(:Grenadier).should == true
    end
  end

  describe '#has_enough_attack_points_to_attack?' do
    it "should return false if the unit's attacks >= attack_phases" do
      u = Unit.new(:Infantry, 1, 10, 10)
      u.attacks = u.attack_phases
      u.has_enough_attack_points_to_attack?.should == false
    end

    it "should return true if the unit's attacks < attack_phases" do
      u = Unit.new(:Infantry, 1, 10, 10)
      u.attacks = 0
      u.has_enough_attack_points_to_attack?.should == true
    end
  end

  describe '#attack_allowed_by_attack_type?' do
    it "should return false if the unit's attack_type is :exclusive and #moved is true" do
      u = Unit.new(:Artillery, 1, 10, 10)
      u.moved = true
      u.attack_allowed_by_attack_type?.should == false
    end

    it "should return true if the unit's attack_type is :exclusive and #moved is false" do
      u = Unit.new(:Mortar, 1, 10, 10)
      u.moved = false
      u.attack_allowed_by_attack_type?.should == true
    end

    it "should return true if the unit's attack_type is :move_attack" do
      u = Unit.new(:Infantry, 1, 10, 10)
      u.moved = true
      u.attack_allowed_by_attack_type?.should == true
    end

    it "should return true if the unit's attack_type is :free" do
      u = Unit.new(:Humvee, 1, 10, 10)
      u.moved = true
      u.attack_allowed_by_attack_type?.should == true
    end
  end

  describe '#melee_attack?' do
    it "should return true if the unit's minimum range is 1" do
      Unit.new(:Infantry, 1, 10, 10).melee_attack?.should == true
    end

    it "should return false if the unit's minimum range is > 1" do
      Unit.new(:Mortar, 1, 10, 10).melee_attack?.should == false
    end
  end

  describe '#can_zoc_unit_type?(unit_type)' do
    it "should return false if zoc is normal and unit is unable to attack the given unit_type" do
      Unit.new(:Infantry, 1, 10, 10).can_zoc_unit_type?(:Fighter).should == false
    end

    it "should return false if the unit has no melee range" do
      Unit.new(:Mortar, 1, 10, 10).can_zoc_unit_type?(:Infantry).should == false
    end

    it "should return false if the unit definition has a zoc of false" do
      Unit.new(:Fighter, 1, 10, 10).can_zoc_unit_type?(:Infantry).should == false
    end

    it "should return false if the unit definition has a zoc of an array of armor types which does not include the given unit type's armor type" do
      Unit.new(:Gunship, 1, 10, 10).can_zoc_unit_type?(:Fighter).should == false
    end

    it "should return true if the unit definition has a zoc of an array of armor types which include the given unit type's armor type" do
      Unit.new(:Gunship, 1, 10, 10).can_zoc_unit_type?(:Tank).should == true
    end

    it "should return true if zoc is normal and the unit is able to attack the given unit_type at melee range" do
      Unit.new(:Infantry, 1, 10, 10).can_zoc_unit_type?(:Grenadier).should == true
    end
  end

  describe "#can_capture?" do
    it "should return false for units which can capture" do
      Unit.new(:Tank, 1, 10, 10).can_capture?.should == false
    end

    it "should return true for units which cannot capture" do
      Unit.new(:Infantry, 1, 10, 10).can_capture?.should == true
    end
  end

  describe '#copy_attributes_to_unit(unit)' do
    it "should set given unit's attributes to be the same as its own" do
      u1 = Unit.new(:Infantry, 1, 10, 10)
      u2 = Unit.new(:Tank, 2, 11, 11)

      u1.copy_attributes_to_unit(u2)

      u2.unit_type.should == :Infantry
      u2.player.should == 1
      u2.x.should == 10
      u2.y.should == 10
    end
  end
end
