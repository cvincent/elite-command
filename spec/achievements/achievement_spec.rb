require 'spec_helper'

describe Achievement do
  before do
    unless defined?(TestAchievement)
      TestAchievement = Class.new(Achievement) do
        triggered_on :end_turn

        def enqueue_check!(payload)
          # Nothing
        end
      end
    end

    unless defined?(TestTieredAchievement)
      TestTieredAchievement = Class.new(Achievement) do
        triggered_on :attack
        has_tiers 1, 5, 10, 15, 20, 25, 50

        def enqueue_check!(payload)
          # Nothing
        end
      end
    end

    unless defined?(TestTieredAchievement2)
      TestTieredAchievement2 = Class.new(Achievement) do
        triggered_on :custom
        has_tiers 5, 10, 20

        def enqueue_check!(payload)
          # Nothing
        end
      end
    end
  end

  describe '#tiered?' do
    it 'should return a boolean' do
      TestAchievement.tiered?.should be_false
      TestTieredAchievement.tiered?.should be_true
    end
  end

  describe '#tier_for_count(count)' do
    it 'should return correct count for tier' do
      TestTieredAchievement.tier_for_count(1).should == 1
      TestTieredAchievement.tier_for_count(4).should == 1
      TestTieredAchievement.tier_for_count(5).should == 5
      TestTieredAchievement.tier_for_count(8).should == 5
      TestTieredAchievement.tier_for_count(100).should == 50

      TestTieredAchievement2.tier_for_count(4).should == 0
      TestTieredAchievement2.tier_for_count(5).should == 5
      TestTieredAchievement2.tier_for_count(6).should == 5
    end
  end

  describe '#achievements' do
    it 'should return an array of Achievement subclasses' do
      achs = Achievement.achievements
      achs.should include(TestAchievement)
      achs.should include(TestTieredAchievement)
      achs.should include(TestTieredAchievement2)
    end
  end

  describe '#triggered_by?(event)' do
    it 'should return true if the Achievement is .triggered_on(event)' do
      TestAchievement.triggered_on?(:end_turn).should be_true
      TestAchievement.triggered_on?(:attack).should be_false
      TestAchievement.triggered_on?(:custom).should be_false
    end
  end
end
