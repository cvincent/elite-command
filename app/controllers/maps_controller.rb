class MapsController < ApplicationController
  before_filter :scrub_map_params

  respond_to :html, :json

  def index
    params[:page] &&= params[:page].to_i
    params[:page] ||= 0
    @maps = Map.published
    
    if params[:pop]
      @maps = @maps.desc(:play_count)
    else
      @maps = @maps.desc(:updated_at)
    end

    @published_maps = Map.published.where(:user_id => current_user.id.to_s) rescue []
    @unpublished_maps = Map.unpublished.where(:user_id => current_user.id.to_s) rescue []
  end

  def show
    @map = Map.find(params[:id])
    @game = Game.new(:map => @map)
    @game.send(:setup_state)

    respond_to do |format|
      format.html
      format.json { render json: @map }
    end
  end

  def new
    @map = Map.new(params[:map])
  end

  def create
    @map = Map.new(params[:map])
    @map.user_id = current_user.id.to_s
    
    if current_user.account_type == 'subscriber' and @map.save
      redirect_to edit_map_url(@map), :notice => 'Your map has been saved successfully.'
    else
      render :action => :new
    end
  end

  def clone
    if current_user.account_type == 'subscriber'
      @map = Map.find(params[:id])
      @new = Map.new(
        :name => @map.name + ' copy', :description => @map.description,
        :bases => @map.bases, :units => @map.units
      )
      @new.tiles = @map.tiles.dup
      @new.user_id = current_user.id.to_s
      @new.save

      redirect_to edit_map_url(@new)
    end
  end

  def edit
    if @map = Map.unpublished.where(user_id: current_user.id).find(params[:id])
      @game = Game.new(:map => @map)
      @game.send(:setup_state)
    else
      redirect_to maps_url
    end
  end

  def update
    if @map = Map.unpublished.where(:user_id => current_user.id).find(params[:id])
      if @map.update_attributes(params[:map])
        respond_with(@map) do |format|
          format.html { redirect_to @map, :notice => 'Your map has been saved successfully.' }
          format.json { render :json => { :success => true } }
        end
      else
        respond_with(@map) do |format|
          format.html { render :action => :edit, :error => 'Your map could not be saved.' }
          format.json { render :json => { :success => false, :errors => @map.errors.full_messages } }
        end
      end
    else
      redirect_to maps_url
    end
  end

  protected

  def scrub_map_params
    if params[:map]
      params[:map][:tiles] &&= JSON.parse(params[:map][:tiles])
      params[:map][:bases] &&= JSON.parse(params[:map][:bases])
      params[:map][:units] &&= JSON.parse(params[:map][:units])
      params[:map][:terrain_modifiers] &&= JSON.parse(params[:map][:terrain_modifiers])
      params[:map].delete(:user_id)
      params[:map].delete(:official)
      params[:map].delete(:img_full)
      params[:map].delete(:img_medium)
    end
  end
end
