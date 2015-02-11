class UserActivation
  include Mongoid::Document

  field :action_name, :type => String
  field :user_id, :type => String
  field :user_tid, :type => String
  field :user_src, :type => String
  field :period, :type => Integer
  field :period_starting, :type => Time

  ACTIVATION_EVENTS = [
    'in_game',
    'invite',
    'signup',
    /game_action_[0-9]+/,
    /game_ended_turn_[0-9]+/
  ]

  PERIODS = [
    [1.day,  :at_midnight],
    [1.week, :at_beginning_of_week]
  ]

  def self.activate(user, action_name, at = Time.now)
    activation = ACTIVATION_EVENTS.any? do |str|
      if str.is_a?(String) and str == action_name
        true
      elsif str.is_a?(Regexp) and action_name =~ str
        true
      end
    end

    if activation
      PERIODS.each do |(period, time_modifier)|
        upsert = {
          action_name: action_name,
          user_id: user.id.to_s,
          user_tid: user.tid,
          user_src: user.src,
          period: period.to_i,
          period_starting: at.send(time_modifier)
        }

        UserActivation.db.collection('user_activations').update(
          upsert.except(:action_name), upsert, upsert: true
        )
      end
    end
  end

  def self.retention(src, period_name)
    period = 1.send(period_name)
    conds = { user_src: src, period: period }
    conds.delete(:user_src) if src == 'all'

    first_period = UserActivation.where(conds).asc(:period_starting).first.try(:period_starting)
    last_period  = UserActivation.where(conds).desc(:period_starting).first.try(:period_starting)

    if first_period and last_period
      period_start = first_period
      counts = []

      while period_start <= last_period
        count = UserActivation.where(conds.merge(period_starting: period_start)).count
        counts << { time: Time.at(first_period), active: count }

        period_start += 1.send(period_name)
      end

      counts
    else
      []
    end
  end
end
