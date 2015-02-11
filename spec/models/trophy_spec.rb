require 'spec_helper'

describe Trophy do
  before do
    @user1 = Fabricate(:user)
    @user2 = Fabricate(:user)
  end

  describe '#grant!(user, defeated_user)' do
    it "should create a Trophy record for the user with the defeated user, denormalizing the defeated user's username" do
      Trophy.grant!(@user1, @user2)

      t = Trophy.where(user_id: @user1.id.to_s, defeated_user_id: @user2.id.to_s).first
      t.should_not be_nil
      t.defeated_username.should == @user2.username
    end

    it "should not create duplicate records" do
      Trophy.grant!(@user1, @user2)
      Trophy.grant!(@user1, @user2)

      Trophy.where(user_id: @user1.id.to_s, defeated_user_id: @user2.id.to_s).count.should == 1
    end
  end
end
