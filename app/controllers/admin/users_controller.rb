class Admin::UsersController < ApplicationController
  before_filter :ensure_dris

  def switch
  end

  def login_as
    session[:user] = User.where(username: params[:username]).first.id
    redirect_to '/'
  end
end
