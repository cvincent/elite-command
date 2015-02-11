require 'spec_helper'

describe UserActivation do
  before do
    @user1 = Fabricate(:user, :src => '1')
    @user2 = Fabricate(:user, :src => '1')
    @user3 = Fabricate(:user, :src => '1')
    @user4 = Fabricate(:user, :src => '2')
    @user5 = Fabricate(:user, :src => '3')
    @user6 = Fabricate(:user)
  end

  before(:each) do
    UserActivation.delete_all
  end

  it "should record and correctly calculate daily and weekly activation numbers, ignoring activations by duplicate users" do
    pending('daylight savings issue...')

    [[:days, :at_midnight], [:weeks, :at_beginning_of_week]].each do |(period, beginning)|
      Time.stub(:now => Time.now)
      start_time = Time.now

      UserActivation.activate(@user1, 'signup')
      UserActivation.activate(@user2, 'signup')
      UserActivation.activate(@user3, 'signup')
      UserActivation.activate(@user4, 'signup')
      UserActivation.activate(@user4, 'signup')

      Time.stub(:now => start_time + 1.send(period))

      UserActivation.activate(@user2, 'signup')
      UserActivation.activate(@user3, 'signup')
      UserActivation.activate(@user3, 'signup')
      UserActivation.activate(@user4, 'signup')
      UserActivation.activate(@user5, 'signup')

      Time.stub(:now => start_time + 3.send(period))

      UserActivation.activate(@user1, 'signup')
      UserActivation.activate(@user5, 'signup')
      UserActivation.activate(@user5, 'signup')

      ret1 = UserActivation.retention('1', period)

      ret1[0][:time].to_i.should == (Time.now - 3.send(period)).send(beginning).to_i
      ret1[0][:active].should == 3
      ret1[1][:time].to_i.should == (Time.now - 2.send(period)).send(beginning).to_i
      ret1[1][:active].should == 2
      ret1[2][:time].to_i.should == (Time.now - 1.send(period)).send(beginning).to_i
      ret1[2][:active].should == 0
      ret1[3][:time].to_i.should == (Time.now - 0.send(period)).send(beginning).to_i
      ret1[3][:active].should == 1

      ret2 = UserActivation.retention('2', period)

      ret2[0][:time].to_i.should == (Time.now - 3.send(period)).send(beginning).to_i
      ret2[0][:active].should == 1
      ret2[1][:time].to_i.should == (Time.now - 2.send(period)).send(beginning).to_i
      ret2[1][:active].should == 1
      ret2[2].should be_nil

      ret3 = UserActivation.retention('3', period)

      ret3[0][:time].to_i.should == (Time.now - 2.send(period)).send(beginning).to_i
      ret3[0][:active].should == 1
      ret3[1][:time].to_i.should == (Time.now - 1.send(period)).send(beginning).to_i
      ret3[1][:active].should == 0
      ret3[2][:time].to_i.should == (Time.now - 0.send(period)).send(beginning).to_i
      ret3[2][:active].should == 1
      ret3[3].should be_nil

      retall = UserActivation.retention('all', period)

      retall[0][:time].to_i.should == (Time.now - 3.send(period)).send(beginning).to_i
      retall[0][:active].should == 4
      retall[1][:time].to_i.should == (Time.now - 2.send(period)).send(beginning).to_i
      retall[1][:active].should == 4
      retall[2][:time].to_i.should == (Time.now - 1.send(period)).send(beginning).to_i
      retall[2][:active].should == 0
      retall[3][:time].to_i.should == (Time.now - 0.send(period)).send(beginning).to_i
      retall[3][:active].should == 2

      UserActivation.retention(nil, period).should be_empty

      UserActivation.activate(@user6, 'signup')
      UserActivation.activate(@user6, 'invite')

      retnone = UserActivation.retention(nil, period)

      retnone[0][:time].to_i.should == Time.now.send(beginning).to_i
      retnone[0][:active].should == 1

      UserActivation.delete_all
    end
  end

  it "should not activate non-activation events" do
    UserActivation.activate(@user1, 'signup_page')
    UserActivation.activate(@user1, 'invite_via_email')

    UserActivation.retention('1', :days).should be_empty
  end

  it "should activate events which are matched via regex" do
    UserActivation.activate(@user1, 'game_action_0')
    UserActivation.activate(@user2, 'game_ended_turn_11')

    UserActivation.retention('1', :days)[0][:active].should == 2
  end

  it "should not count different action_name activations as unique" do
    UserActivation.activate(@user1, 'signup')
    UserActivation.activate(@user1, 'invite')

    UserActivation.retention('1', :days)[0][:active].should == 1
  end
end
