require 'spec_helper'

describe GamesController do
  before do
    TestCommand ||= Class.new(GameCommand) do
      def execute
        { :test_response => 'cool' }
      end

      def unexecute
        { :test_unexecute_response => 'sweet' }
      end
    end

    TestCommand2 ||= Class.new(GameCommand) do
      def execute
        { :test_response => 'cool2' }
      end

      def unexecute
        { :test_unexecute_response => 'sweet2' }
      end
    end

    @game = Game.create(:name => 'test', :map => Fabricate(:basic_1v1_map), :time_limit => 1.hour)
    @user = Fabricate(:user)
    session[:user] = @user._id

    @params = HashWithIndifferentAccess.new(
      :id => @game.id, :command => 'test_command',
      :param_1 => 'a', :param_2 => 'b'
    )
    @test_command = TestCommand.new(@game, @user, @params)
    @test_command2 = TestCommand2.new(@game, @user, @params)

    @composite_params = HashWithIndifferentAccess.new(
      :id => @game.id, :commands => {
        '0' => { :command => 'test_command', :param_1 => 'a', :param_2 => 'b' },
        '1' => { :command => 'test_command2', :param_1 => 'aa', :param_2 => 'bb' }
      }
    )
  end

  describe '#execute_command' do
    it 'should instantiate a GameCommand subclass using the provided command name, supplying the Game instance, current_user, and the params' do
      TestCommand.should_receive(:new).with(@game, @user, @params).and_return(@test_command)
      post :execute_command, @params
    end

    it 'should convert strings to integers when necessary, "null" to nil, and "false" to false' do
      orig_params = HashWithIndifferentAccess.new(
        :id => @params[:id], :command => 'test_command', :param1 => '1', :param2 => 'null', :param3 => 'false'
      )

      clean_params = HashWithIndifferentAccess.new(
        :id => @params[:id], :command => 'test_command', :param1 => 1, :param2 => nil, :param3 => false
      )

      TestCommand.should_receive(:new).with(@game, @user, clean_params).and_return(@test_command)
      post :execute_command, orig_params
    end

    it "should instantiate a CompositeGameCommand, add each command from the params[commands] array, and execute it" do
      cgc = CompositeGameCommand.new(@game, @user)
      tc1 = TestCommand.new(@game, @user, @composite_params[:commands]['0'])
      tc2 = TestCommand2.new(@game, @user, @composite_params[:commands]['1'])

      CompositeGameCommand.should_receive(:new).with(@game, @user).and_return(cgc)
      TestCommand.should_receive(:new).with(@game, @user, @composite_params[:commands]['0']).and_return(tc1)
      TestCommand2.should_receive(:new).with(@game, @user, @composite_params[:commands]['1']).and_return(tc2)
      cgc.should_receive(:<<).with(tc1).ordered
      cgc.should_receive(:<<).with(tc2).ordered
      # No longer necessary for some reason... the marshal doesn't seem to be called
      # on the mock object, even though the mock object is passed through. Perhaps
      # RSpec has fixed this?
      # cgc.should_receive(:marshal_dump).and_return('') # Prevents method expectations from crashing on marshal

      cgc.stub(:to_json_hash => {})

      post :execute_command, @composite_params
    end

    it "should serialize a successful command and save it to the game's command history" do
      post :execute_command, @params

      @game = Game.find(@game._id)
      saved_command = @game.command_history.last
      saved_command.should be_a(TestCommand)
      saved_command.instance_variable_get(:@game).should == @game
      saved_command.instance_variable_get(:@user).should == @user

      params = saved_command.instance_variable_get(:@params)
      params[:param_1].should == 'a'
      params[:param_2].should == 'b'
    end

    it 'should render a successful JSON response merged with the return of GameCommand#execute!' do
      post :execute_command, @params
      JSON.parse(response.body).should == JSON.parse({ :success => true, :test_response => 'cool' }.to_json)
    end

    it 'should render a failure JSON response merged with the exception message if a CommandError is raised' do
      TestCommand.should_receive(:new).and_return(@test_command)
      @test_command.should_receive(:execute).and_raise(CommandError.new('Fail!'))
      #@test_command.should_receive(:to_json_hash).and_return({here: 'there'})
      post :execute_command, @params

      JSON.parse(response.body).should == JSON.parse({
        :success => false, :error => 'Fail!'
      }.to_json)
    end
  end

  describe '#unexecute_last_command' do
    before do
      IrreversibleTestCommand ||= Class.new(GameCommand) do
        def unexecute
          raise IrreversibleCommand
        end
      end

      AffectiveTestCommand ||= Class.new(GameCommand) do
        def unexecute
          @game.name = 'it worked'
        end
      end

      @other_user_test_command = TestCommand.new(@game, Fabricate(:user))

      @game.command_history << @test_command
      @game.save
      @game.reload
    end

    it "should return an error response if the game has no commands recorded" do
      @game.command_history = []
      @game.save
      @game.reload

      post :unexecute_last_command, :id => @game.id

      JSON.parse(response.body).should == JSON.parse({
        :success => false, :error => "No command to undo."
      }.to_json)
    end

    it "should return an error response if the game's last command is irreversible" do
      @game.command_history << IrreversibleTestCommand.new(@game, @user)
      @game.save
      @game.reload

      post :unexecute_last_command, :id => @game.id

      JSON.parse(response.body).should == JSON.parse({
        :success => false, :error => "Cannot undo last command."
      }.to_json)
    end

    it "should return an error response if the game's last command is from another player" do
      @game.command_history << @other_user_test_command
      @game.save
      @game.reload

      post :unexecute_last_command, :id => @game.id

      JSON.parse(response.body).should == JSON.parse({
        :success => false, :error => "Last command was from a different user."
      }.to_json)
    end

    it "should unexecute and remove the last command and render a successful response" do
      @game.command_history << AffectiveTestCommand.new(@game, @user)
      @game.save
      @game.reload

      post :unexecute_last_command, :id => @game.id

      JSON.parse(response.body).should == JSON.parse({
        :success => true
      }.to_json)
      @game = Game.find(@game.id)
      @game.name.should == 'it worked'
      @game.command_history.size.should == 1
    end
  end
end

