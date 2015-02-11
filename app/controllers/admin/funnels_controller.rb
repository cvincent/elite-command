class Admin::FunnelsController < ApplicationController
  before_filter :ensure_dris
  before_filter :load_steps
  before_filter :scrub_params

  def index
    @funnels = Funnel.all
  end

  def show
    @funnels = Funnel.all
    @funnel = Funnel.find(params[:id])

    @user_srcs = UserAction.all.distinct(:user_src).map do |src|
      src.nil? ? ['No Source', 'none'] : [src, src]
    end
    @user_srcs = [['All Sources', 'all']] + @user_srcs

    params[:user_src_1] ||= 'all'
    params[:user_src_2] ||= 'all'

    @step_results_1 = @funnel.step_results(params[:user_src_1])
    @step_results_2 = @funnel.step_results(params[:user_src_2])
  end

  def new
    @funnel = Funnel.new
  end

  def create
    @funnel = Funnel.new(params[:funnel])

    if @funnel.save
      redirect_to admin_funnel_url(@funnel), :notice => 'Funnel saved.'
    else
      flash.now[:alert] = 'Funnel could not be saved.'
      render :action => :new
    end
  end

  def edit
    @funnel = Funnel.find(params[:id])
  end

  def update
    @funnel = Funnel.find(params[:id])
    @funnel.update_attributes(params[:funnel])

    if @funnel.save
      redirect_to admin_funnel_url(@funnel), :notice => 'Funnel saved.'
    else
      flash.now[:alert] = 'Funnel could not be saved.'
      render :action => :edit
    end
  end

  def destroy
    @funnel.delete(params[:id])
    redirect_to funnels_url, :notice => 'Funnel deleted.'
  end

  protected

  def load_steps
    @steps = UserAction.all.distinct(:name)
  end

  def scrub_params
    if params[:funnel] and params[:funnel][:steps]
      params[:funnel][:steps] = params[:funnel][:steps].keys.map(&:to_i).sort.map do |i|
        params[:funnel][:steps][i.to_s]
      end
    end
  end
end
