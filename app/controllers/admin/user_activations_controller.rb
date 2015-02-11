class Admin::UserActivationsController < ApplicationController
  before_filter :ensure_dris

  def index
    params[:src_1] ||= 'all'
    params[:src_2] ||= 'all'

    src_1, src_2 = params[:src_1], params[:src_2]
    src_1 = nil if src_1 == 'none'
    src_2 = nil if src_2 == 'none'

    @user_srcs = UserAction.all.distinct(:user_src).map do |src|
      src.nil? ? ['No Source', 'none'] : [src, src]
    end
    @user_srcs = [['All Sources', 'all']] + @user_srcs

    @retention_1_days  = UserActivation.retention(params[:src_1], :days)
    @retention_1_weeks = UserActivation.retention(params[:src_1], :weeks)

    @retention_2_days  = UserActivation.retention(params[:src_2], :days)
    @retention_2_weeks = UserActivation.retention(params[:src_2], :weeks)
  end
end
