class HomeController < ApplicationController
  def index
  end

  def tutorial
  end

  def why_subscribe
  end

  def donate
  end

  def thank_you
  end

  def heartbeat
    render :text => 'OK', :layout => false
  end
end
