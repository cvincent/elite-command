class MessagesController < ApplicationController
  before_filter :ensure_logged_in
  before_filter :clean_params, :only => :create

  # GET /messages
  # GET /messages.xml
  def index
    @messages = Message.latest_threads_for_user(current_user)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @messages }
    end
  end

  # GET /messages/new
  # GET /messages/new.xml
  def new
    @message = Message.new(to_user_id: params[:to_user_id])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(params[:message])

    respond_to do |format|
      if @message.save
        UserMailer.private_message(@message).deliver rescue nil
        Orbited.send_data("user_#{@message.receiver.id.to_s}", {
          msg_class: 'game_alert',
          game_alert: GameAlert.new_message(@message)
        }.to_json)

        format.html { redirect_to(messages_url, :notice => 'Message was successfully created.') }
        format.xml  { render :xml => @message, :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  def thread
    @messages = Message.where(thread_identifier: params[:id]).asc(:created_at)
    Message.collection.update(
      { thread_identifier: params[:id], to_user_id: current_user.id.to_s, unread: true },
      { :$set => { unread: false }},
      multi: true
    )

    @other_user = @messages[0].other_user(current_user)
    @message = Message.new(to_user_id: @other_user.id.to_s)
  end

  protected

  def clean_params
    if params[:message]
      params[:message][:from_user_id] = current_user.id.to_s
    end
  end
end
