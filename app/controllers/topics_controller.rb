class TopicsController < ApplicationController
  before_filter :load_global_chat, only: :show
  before_filter :ensure_logged_in, :except => :show
  before_filter :ensure_forum, :except => [:show, :create_reply, :subscribe, :unsubscribe]
  
  helper_method :page, :per_page
  
  def new
    @topic = Topic.new(:user_id => current_user._id)
  end
  
  def create
    @topic = Topic.new(params[:topic].merge(:user_id => current_user._id, :forum_id => @forum._id, :subscribe => params[:subscribe]))
    
    if @topic.save
      redirect_to topic_url(@topic), :notice => 'Your topic has been posted.'
    else
      flash.now[:alert] = 'Your topic could not be posted.'
      render :action => :new
    end
  end
  
  def create_reply
    @topic = Topic.find(params[:id])
    @reply = Reply.create(:topic_id => @topic._id, :user_id => current_user._id, :body => params[:reply][:body])
    
    if @reply.save
      @topic.updated_at = Time.now
      params[:subscribe] == '1' ? @topic.add_subscriber(current_user) : @topic.remove_subscriber(current_user)
      @topic.save
      
      @topic.subscribers.each do |uid|
        user = User.find(uid.to_s)
        UserMailer.forum_reply(@reply, user).deliver unless user == @reply.user rescue nil
      end
      
      redirect_to topic_url(@topic), :notice => 'Your reply has been posted.'
    else
      flash.now[:alert] = 'Your reply could not be posted.'
      render :action => :show
    end
  end

  def subscribe
    @topic = Topic.find(params[:id])
    @topic.add_subscriber(current_user)
    @topic.save
    logger.info @topic.inspect

    redirect_to topic_url(@topic), :notice => 'You will now receive updates when this topic receives replies.'
  end
  
  def unsubscribe
    @topic = Topic.find(params[:id])
    @topic.remove_subscriber(current_user)
    @topic.save
    logger.info @topic.inspect

    redirect_to topic_url(@topic), :notice => 'You will no longer receive updates about this topic.'
  end
  
  def show
    @topic = Topic.find(params[:id])
    @forum = @topic.forum
    @reply = Reply.new
  end
  
  protected
  
  def page
    @page ||= (params[:page].try(:to_i) || 0)
  end
  
  def per_page
    @per_page ||= 20
  end
  
  def ensure_forum
    @forum = Forum.find(params[:forum_id])
  rescue Mongoid::Errors::InvalidOptions
    redirect_to forums_url
  end
end
