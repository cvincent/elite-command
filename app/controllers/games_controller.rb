class GamesController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:invite_via_email, :new_player_join]
  before_filter :ensure_logged_in, :except => [:show, :index]
  before_filter :load_global_chat, only: [:index]

  helper_method :game, :games

  def new
    @game = Game.new(params[:game])
    UserAction.record('start_game_page', user: current_user, cookies: cookies)
    UserAction.record('pre_game_page', user: current_user, cookies: cookies)
  end
  
  def create
    @game = Game.create(params[:game])

    if (@game.map.free or current_user.account_type == 'subscriber') and @game.save
      @game.add_player!(current_user)

      UserAction.record('game_creation', user: current_user, cookies: cookies)
      UserAction.record('in_game', user: current_user, cookies: cookies)
      UserAction.record('in_game_' + (@game.new_player ? 'servo' : 'human'), user: current_user, cookies: cookies)

      ActiveSupport::Notifications.instrument('ec.game_started', game: @game)

      redirect_to game_url(@game, :new_game => 'true'), :notice => 'Game created successfully. It\'s your turn.'
    else
      render :action => :new
    end
  end

  def show
    if params[:new_game]
      flash[:new_game] = 'true'
      redirect_to game
    elsif params[:won_game]
      flash[:won_game] = 'true'
      redirect_to game
    end
  end

  def index
    UserAction.record('join_game_page', user: current_user, cookies: cookies)
    UserAction.record('pre_game_page', user: current_user, cookies: cookies)
  end

  def new_player_join
    UserAction.record('game_join_for_new_player_from_' + params[:game_join_source], user: current_user, cookies: cookies)

    if @game = Game.available_to_player(current_user).where(:new_player => true).first
      join
    else
      params[:game] = {
        name: 'There is no chance to survive',
        map_id: Map.official.where(:name => 'Little Island').first._id,
        time_limit: 24.hours,
        new_player: true,
        unrated: true
      }

      create

      tom = User.where(:username => 'TomServo').first
      @game.add_player!(tom)
      @game.update_player_subscription(current_user, false)
      @game.update_player_subscription(tom, false)
    end
  end

  def update_subscription
    game.update_player_subscription(current_user, params[:subscribed?] == 'true')
    render :json => { :success => true }.to_json
  end

  def toggle_peace
    game.update_player_peace_offer(current_user, !game.player_offered_peace?(current_user))
    message = {
      :msg_class => :player_peace_treaty,
      :user => current_user.to_json_hash,
      :status => game.player_offered_peace?(current_user),
      :info_message => {
        :msg_class => :info_message,
        :message => "#{current_user.username} #{game.player_offered_peace?(current_user) ? 'offered peace' : 'no longer offers peace'}.",
        :user_id => current_user.id.to_s
      }
    }
    Orbited.send_data("game_#{game._id}", message.to_json)
    game.append_to_chat_log!(message[:info_message])

    render :json => { :success => true }
  end

  def join
    if game.add_player!(current_user)
      message = {
        :msg_class => :new_player,
        :user => current_user.to_json_hash,
        :info_message => {
          :msg_class => :info_message,
          :message => "#{current_user.username} joined.",
          :user_id => current_user._id
        }
      }
      Orbited.send_data("game_#{game._id}", message.to_json)
      game.append_to_chat_log!(message[:info_message])
      UserAction.record('game_join', user: current_user, cookies: cookies)
      UserAction.record('in_game', user: current_user, cookies: cookies)
      UserAction.record('in_game_' + (game.new_player ? 'servo' : 'human'), user: current_user, cookies: cookies)

      redirect_to game
    else
      redirect_to games_url
    end
  end

  def invite_via_email
    errors = []

    if params[:inviter_name].blank?
      errors << 'You must provide your name.'
    end

    if params[:invitee_email].blank? or !(params[:invitee_email] =~ /^.+@.+$/)
      errors << 'You must provide a valid email.'
    end

    if errors.size == 0
      UserMailer.invite(game, params[:invitee_email], params[:inviter_name], params[:message]).deliver rescue nil
      UserAction.record('invite_via_email', user: current_user, cookies: cookies)
      UserAction.record('invite', user: current_user, cookies: cookies)
      render :json => { :success => true }
    else
      render :json => { :success => false, :errors => errors }
    end
  end

  def invite_via_ec
    errors = []

    if !@user = User.where(:username => params[:username]).first
      errors << 'You must enter a valid username.'
    end

    if errors.size == 0
      UserMailer.invite(game, @user.email, current_user.username, params[:message], true).deliver rescue nil
      UserAction.record('invite_via_ec', user: current_user, cookies: cookies)
      UserAction.record('invite', user: current_user, cookies: cookies)
      render :json => { :success => true }
    else
      render :json => { :success => false, :errors => errors }
    end
  end

  def leave
    if game.remove_player!(current_user)
      message = { :msg_class => :info_message, :message => "#{current_user.username} left.", :user_id => current_user._id }
      game.append_to_chat_log!(message)
      Orbited.send_data("game_#{game._id}", message.to_json)
      redirect_to current_user
    else
      redirect_to game
    end
  end

  def kick_user
    kick_me = User.find(params[:user_id])
    if current_user and current_user == game.creator and game.remove_player!(kick_me)
      message = { :msg_class => :info_message, :message => "#{current_user.username} kicked #{kick_me.username} from the game.", :user_id => current_user._id }
      game.append_to_chat_log!(message)
      Orbited.send_data("game_#{game._id}", message.to_json)
      redirect_to game
    else
      redirect_to game
    end
  end

  def execute_command
    if params[:command]
      command_class = params[:command].camelize.constantize
      @command = command_class.new(game, current_user, clean_command_params(params.except(:controller, :action)))
      result = @command.execute
      game.save
    elsif params[:commands]
      @command = CompositeGameCommand.new(game, current_user)

      params[:commands].keys.map(&:to_i).sort.each do |i|
        command_class = params[:commands][i.to_s][:command].camelize.constantize
        cmd = command_class.new(game, current_user, clean_command_params(params[:commands][i.to_s]))
        @command << cmd
      end

      result = { :result => @command.execute }
      game.save
    end

    Orbited.send_data(
      "game_#{game._id}",
      { :msg_class => 'execute_game_command', :cmd => @command.to_json_hash }.to_json
    )

    game.push_command!(@command)

    render :json => { :success => true }.merge(result)
  rescue CommandError => e
    UserMailer.command_error(@game, @command, e).deliver rescue nil
    render :json => { :success => false, :error => e.message }
  end

  def unexecute_last_command
    g = Game.find_by_identity(params[:id].to_s)
    command = g.command_history.pop
    result = {}

    if command.nil?
      result = { :success => false, :error => "No command to undo." }
    elsif command.user != current_user
      result = { :success => false, :error => "Last command was from a different user." }
    else
      begin
        command.unexecute!
        result = { :success => true }
      rescue IrreversibleCommand
        result = { :success => false, :error => "Cannot undo last command." }
      end
    end

    if command
      Orbited.send_data("game_#{g._id}", { :msg_class => 'unexecute_game_command', :cmd => command.to_json_hash }.to_json)
    end

    render :json => result.to_json
  rescue CommandError => e
    UserMailer.command_error(@game, command, e).deliver rescue nil
    render :json => { :success => false }
  end

  def command_history
    g = Game.find_by_identity(params[:id].to_s)

    if params[:page] == 'current_round'
      render json: { commands: g.current_round_commands.map(&:to_json_hash) }
    else
      render json: { commands: g.command_page(params[:page].to_i).map(&:to_json_hash) }
    end
  end

  def chat
    message = { :msg_class => :chat_message, :message => "#{params[:message]}", :user_id => current_user._id }
    game.append_to_chat_log!(message)
    Orbited.send_data("game_#{game._id}", message.to_json)
    render :json => { :success => true }
  end
  
  protected

  def game
    @game ||= (params[:id] ? Game.find(params[:id]) : nil)
  end

  def games
    @games ||= Game.available_to_player(current_user).visible_to_public
  end

  def clean_command_params(cmd)
    ccmd = HashWithIndifferentAccess.new

    cmd.each do |k, v|
      if v == 'null'
        ccmd[k] = nil
      elsif v == 'false'
        ccmd[k] = false
      elsif v == 'true'
        ccmd[k] = true
      elsif v.is_a?(BSON::ObjectId)
        ccmd[k] = v
      else
        begin
          ccmd[k] = Integer(v)
        rescue ArgumentError
          ccmd[k] = v
        end
      end
    end

    ccmd
  end
end
