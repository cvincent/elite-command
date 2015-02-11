class Funnel
  include Mongoid::Document

  field :name, :type => String
  field :steps, :type => Array, :default => []

  validates_presence_of :name

  def step_results(src = 'all')
    conds = {}

    if src == 'none'
      conds[:user_src] = nil
    elsif src != 'all'
      conds[:user_src] = src
    end

    last_user_tids = nil

    self.steps.map do |step|
      q = UserAction.where(conds.merge(name: step))

      if last_user_tids.nil?
        last_user_tids = q.distinct(:user_tid)
      else
        last_user_tids = q.where(:user_tid.in => last_user_tids).distinct(:user_tid)
      end

      [step, last_user_tids.size]
    end
  end
end
