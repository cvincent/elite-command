class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :clear_mongoid_identity_map
  before_filter :set_current_user
  before_filter :save_source
  
  helper_method :current_user
  
  protected

  def save_source
    if params[:src]
      cookies[:src] = params[:src]
      cookies[:tid] = User.generate_tid
      UserAction.record('arrival', user: current_user, cookies: cookies)
    end

    if params[:invited] and params[:id]
      cookies[:invited_game_id] = params[:id]
    end
  end

  def set_current_user
    if session[:user]
      @current_user = User.find(session[:user]) rescue nil
    elsif params[:as] and params[:as_pwd]
      if u = User.find(params[:as]) and u.password_hash == params[:as_pwd]
        @current_user = u
      end
    end
  end

  def verify_authenticity_token
    if params[:as] and params[:as_pwd]
      true
    else
      super
    end
  end
  
  def current_user
    @current_user
  end
  
  def ensure_logged_in
    if !current_user
      redirect_to new_user_url, :alert => 'You must be logged in to create or join a game or participate in the forums.'
    end
  end

  def ensure_dris
    if !current_user or current_user.username != 'dris'
      redirect_to root_url
    end
  end

  def clear_mongoid_identity_map
    MongoidIdentityMap::MapHash.clear
    MongoidIdentityMap::MapHash.clear
  end

  def load_global_chat
    @global_chat_messages = GlobalChatMessage.desc(:created_at).limit(50).reverse
  end
end
