require 'digest/md5'

class UsersController < ApplicationController
  before_filter :ensure_logged_in, only: [:edit, :update]
  before_filter :ensure_dris, only: [:announce, :send_announcement]
  skip_before_filter :verify_authenticity_token, :only => [:spreedly_update, :trialpay_update, :paypal_ipn]

  helper_method :inviter, :page, :per_page
  
  def new
    @user = User.new
    UserAction.record('signup_page', user: current_user, cookies: cookies)
  end
  
  def create
    params[:user][:src] = cookies[:src] if cookies[:src]
    params[:user][:tid] = cookies[:tid] if cookies[:tid]

    @user = User.new(params[:user].merge(:invited_by => inviter ? inviter._id : nil))
    @user.account_type = 'subscriber'
    @user.subscription_name = '1-Week Trial'
    @user.subscription_expires_after = Date.today + 7.days

    if @user.save
      session[:user] = @user.id
      UserMailer.welcome(@user).deliver rescue nil
      UserAction.record('signup', user: @user, cookies: cookies)

      if cookies[:invited_game_id] and game = Game.find(cookies[:invited_game_id])
        redirect_to game_url(game), :notice => 'Your account has been created successfully.'
      else
        redirect_to tutorial_url, :notice => 'Your account has been created successfully.'
      end
    else
      render :action => :new
    end
  end
  
  def subscribe_to_waiting_list
    @waiting_list_subscriber = WaitingListSubscriber.new(params[:waiting_list_subscriber])
    
    if @waiting_list_subscriber.save
      render :action => :subscribed
    else
      flash.now[:alert] = 'You must enter a valid email address to be notified when we enter beta. You may only subscribe once.'
      render :action => :new
    end
  end

  def edit
    @user = User.find(params[:id])
    redirect_to root_url unless @user == current_user
  end

  def update
    @user = User.find(params[:id])
    redirect_to(root_url) and return unless @user == current_user
    
    if @user.update_attributes(params[:user])
      redirect_to edit_user_url(@user), :notice => 'Your settings were updated successfully.'
    else
      flash.now[:alert] = 'Your settings could not be updated.'
      render :action => :edit
    end
  end
  
  def index
    @users = User.played.desc(:rating).skip(page * per_page).limit(per_page)
  end

  def usernames
    regexp = /^#{params[:autocomplete_from]}/i
    @users = User.where(:username => regexp).limit(5)
    @users -= [current_user]

    if params[:objs] == '1'
      render :json => { :users => @users.map { |u| u.attributes.slice(:_id, :username) } }
    else
      render :json => { :users => @users.map(&:username) }
    end
  end
  
  def show
    params[:page] ||= 0
    params[:page] = params[:page].to_i
    @user = User.find(params[:id])
  end
  
  def login
    if user = User.find_by_username_and_password(params[:username], params[:password]) and session[:user] = user.id
      redirect_to (params[:r].blank? ? user : params[:r]), :notice => 'Welcome back!'
    else
      redirect_to :back, :alert => 'Username or password is incorrect.'
    end
  end
  
  def logout
    session[:user] = nil
    redirect_to '/', :notice => 'You have been logged out successfully.'
  end

  def forgot_password
  end

  def reset_password
    if @user = User.where(email: params[:email]).first
      new_password = (0...8).map{65.+(rand(25)).chr}.join
      @user.update_attributes(password: new_password, password_confirmation: new_password)
      UserMailer.new_password(@user, new_password).deliver rescue nil

      flash[:notice] = "Your password has been reset and sent to #{params[:email]}."
    else
      flash[:alert] = "Could not find user with email #{params[:email]}."
    end

    redirect_to forgot_password_users_url
  end

  def announce
    if !current_user or current_user.username != 'dris'
      redirect_to root_url
    end
  end

  def send_announcement
    c = 0

    User.where(email_announcements: true).each do |u|
      UserMailer.announcement(u, params[:subject], params[:message]).deliver rescue nil
      c += 1
    end

    redirect_to announce_users_url, :notice => "Email sent to #{c} users."
  end

  def spreedly_update
    params[:subscriber_ids].split(',').each do |id|
      User.find(id).update_spreedly_data!
    end

    head(:ok)
  end

  def paypal_ipn
    if params[:receiver_email] == PAYPAL_AUTH[:merchant_id] and ipn_valid?
      if !params[:txn_id] or txn = PaypalTransaction.create(:txn_id => params[:txn_id])
        user = User.find(params[:custom])
        sub = PAYPAL_SUBS.select { |k, v| v[:identifier] == params[:item_number] }.first[1]

        case params[:txn_type]
        when 'subscr_payment'
          if params[:payment_status] == 'Completed'
            from_date = DateTime.parse(params[:payment_date]).to_date
            user.update_subscription!(sub, from_date)
          end
        when 'subscr_modify'
          from_date = DateTime.parse(params[:subscr_effective]).to_date
          user.update_subscription!(sub, from_date)
        when 'subscr_cancel'
          from_date = DateTime.parse(params[:subscr_date]).to_date
          user.update_subscription!(nil, from_date)
        when 'subscr_eot'
          user.update_subscription!(nil, Date.today)
        end
      else
        raise StandardError.new("PayPal transaction already processed: #{params[:txn_id]}")
      end
    end

    head(:ok)
  end

  def paypal_donation_ipn
    if params[:receiver_email] == PAYPAL_AUTH[:merchant_id] and ipn_valid?
      if !params[:txn_id] or txn = PaypalTransaction.create(:txn_id => params[:txn_id])
        user = User.find(params[:custom])

        if params[:txn_type] == 'web_accept'
          if params[:payment_status] == 'Completed'
            from_date = DateTime.parse(params[:payment_date]).to_date
            Donation.create(user_id: user.id.to_s, amount: params[:mc_gross].gsub('.', '').to_i)
          end
        end
      else
        raise StandardError.new("PayPal transaction already processed: #{params[:txn_id]}")
      end
    end

    head(:ok)
  end

  def trialpay_update
    render :text => Digest::MD5.hexdigest(rand.to_s)
  end
  
  protected
  
  def page
    params[:page].try(:to_i) || 0
  end
  
  def per_page
    20
  end
  
  def inviter
    params[:invite_code].nil? ? nil : @inviter ||= User.where(:invite_code => params[:invite_code], :invites.gt => 0).first
  end

  def ipn_valid?
    uri = URI.parse(PAYPAL_AUTH[:base_uri] + '/webscr?cmd=_notify-validate')

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true

    res = http.post(uri.request_uri, request.raw_post,
                    'Content-Length' => "#{request.raw_post.size}",
                    'User-Agent' => "Elite Command IPN Responder").body

    raise StandardError.new("Faulty PayPal result: #{res}") unless ["VERIFIED", "INVALID"].include?(res)
    raise StandardError.new("Invalid PayPal IPN: #{res}") unless res == "VERIFIED"

    true
  end
end
