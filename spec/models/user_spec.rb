require 'spec_helper'

describe User do
  before do
    unless defined?(TestAchievement)
      TestAchievement = Class.new(Achievement) do
      end

      def enqueue_check!(payload)
        # Nothing
      end
    end

    unless defined?(TestTieredAchievement)
      TestTieredAchievement = Class.new(Achievement) do
        has_tiers 1, 5, 10, 15, 20, 25, 50
      end

      def enqueue_check!(payload)
        # Nothing
      end
    end

    @user_with_empty_achievements = Fabricate(:user, achievements: {})
    @user_with_no_achievements = Fabricate(:user, achievements: {
      'TestAchievement' => 0, 'TestTieredAchievement' => 0
    })

    @user_with_single_achievements = Fabricate(:user, achievements: {
      'TestAchievement' => 1, 'TestTieredAchievement' => 1
    })

    @user_with_tiered_achievements = Fabricate(:user, achievements: {
      'TestAchievement' => 1, 'TestTieredAchievement' => 17
    })
  end

  describe '#achievement_count' do
    it 'should return 0 for no achievements' do
      [@user_with_empty_achievements, @user_with_no_achievements].each do |user|
        user.achievement_count(TestAchievement).should == 0
        user.achievement_count(TestTieredAchievement).should == 0
      end
    end

    it 'should return correct number of times the achievement was achieved' do
      @user_with_single_achievements.achievement_count(TestAchievement).should == 1
      @user_with_single_achievements.achievement_count(TestTieredAchievement).should == 1
      @user_with_tiered_achievements.achievement_count(TestAchievement).should == 1
      @user_with_tiered_achievements.achievement_count(TestTieredAchievement).should == 17
    end
  end

  describe '#tiered_achievement_count' do
    it 'should return 0 for no achievements' do
      [@user_with_empty_achievements, @user_with_no_achievements].each do |user|
        user.tiered_achievement_count(TestAchievement).should == 0
        user.tiered_achievement_count(TestTieredAchievement).should == 0
      end
    end

    it 'should not return anything greater than 1 for an untiered achievement' do
      @user_with_empty_achievements.tiered_achievement_count(TestAchievement).should == 0
      @user_with_empty_achievements.achieved!(TestAchievement)
      @user_with_empty_achievements.tiered_achievement_count(TestAchievement).should == 1
      @user_with_empty_achievements.achieved!(TestAchievement)
      @user_with_empty_achievements.tiered_achievement_count(TestAchievement).should == 1
    end

    it 'should return the correct tiered number of times the achievement was achieved' do
      @user_with_single_achievements.tiered_achievement_count(TestAchievement).should == 1
      @user_with_single_achievements.tiered_achievement_count(TestTieredAchievement).should == 1
      @user_with_tiered_achievements.tiered_achievement_count(TestAchievement).should == 1
      @user_with_tiered_achievements.tiered_achievement_count(TestTieredAchievement).should == 15
    end
  end

  describe '#achieved!' do
    it 'should increment the count for the achievement' do
      [
        @user_with_empty_achievements, @user_with_no_achievements,
        @user_with_single_achievements, @user_with_tiered_achievements
      ].each do |user|
        user.achieved!(TestAchievement)
        user.achieved!(TestTieredAchievement)
      end

      @user_with_empty_achievements.reload.tiered_achievement_count(TestAchievement).should == 1
      @user_with_empty_achievements.reload.tiered_achievement_count(TestTieredAchievement).should == 1
      @user_with_no_achievements.reload.tiered_achievement_count(TestAchievement).should == 1
      @user_with_no_achievements.reload.tiered_achievement_count(TestTieredAchievement).should == 1

      @user_with_single_achievements.reload.tiered_achievement_count(TestAchievement).should == 1
      @user_with_single_achievements.reload.tiered_achievement_count(TestTieredAchievement).should == 1
      @user_with_tiered_achievements.reload.tiered_achievement_count(TestAchievement).should == 1
      @user_with_tiered_achievements.reload.tiered_achievement_count(TestTieredAchievement).should == 15
    end

    it 'should return true if a new tier was achieved' do
      @user_with_empty_achievements.achieved!(TestAchievement).should be_true
      @user_with_empty_achievements.achieved!(TestAchievement).should be_false

      @user_with_no_achievements.achieved!(TestAchievement).should be_true
      @user_with_no_achievements.achieved!(TestAchievement).should be_false

      @user_with_single_achievements.achieved!(TestAchievement).should be_false
      @user_with_single_achievements.achieved!(TestTieredAchievement).should be_false
      @user_with_single_achievements.achieved!(TestTieredAchievement).should be_false
      @user_with_single_achievements.achieved!(TestTieredAchievement).should be_false
      @user_with_single_achievements.achieved!(TestTieredAchievement).should be_true

      @user_with_tiered_achievements.achieved!(TestTieredAchievement).should be_false
      @user_with_tiered_achievements.achieved!(TestTieredAchievement).should be_false
      @user_with_tiered_achievements.achieved!(TestTieredAchievement).should be_true
    end
  end
end

