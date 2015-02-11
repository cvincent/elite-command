class ForumsController < ApplicationController
  before_filter :load_global_chat
  helper_method :page, :per_page
  
  def index
    @forums = Forum.all.asc(:position)
  end
  
  def show
    @forum = Forum.find(params[:id])
  end
  
  protected
  
  def page
    @page ||= (params[:page].try(:to_i) || 0)
  end
  
  def per_page
    @per_page = 20
  end
end
