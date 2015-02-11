require 'spec_helper'

describe CompositeGameCommand do
  before do
    @game = Game.create(
      :name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour
    )
    @user1 = Fabricate(:user)
    @game.add_player!(@user1)

    @cgc = CompositeGameCommand.new(@game, @user1)

    @c1 = MoveUnit.new(@game, @user1, {})
    @c2 = Attack.new(@game, @user1, {})
  end

  describe '#<<' do
    it "should accept another GameCommand" do
      @cgc << @c1
      @cgc << @c2
    end
  end

  describe '#execute' do
    it "should call each added GameCommand#execute in order" do
      # Can't really spec order across multiple objects
      @cgc << @c1
      @cgc << @c2

      @c1.should_receive(:execute).once.ordered
      @c2.should_receive(:execute).once.ordered

      @cgc.execute!
    end
  end

  describe '#unexecute' do
    it "should call each added GameCommand#unexecute in reverse order" do
      # Can't really spec order across multiple objects
      @cgc << @c1
      @cgc << @c2

      @c2.should_receive(:unexecute).once.ordered
      @c1.should_receive(:unexecute).once.ordered

      @cgc.unexecute!
    end
  end
end
