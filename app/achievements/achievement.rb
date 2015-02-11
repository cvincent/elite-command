class Achievement
  class << self
    attr_accessor :tiers

    def inherited(other)
      super if defined? super
    ensure
      (@subclasses ||= []).push(other).uniq!
    end

    def tiers
      @tiers ||= []
    end

    def tiered?
      !self.tiers.blank?
    end

    def tier_for_count(count)
      return nil if self.tiers.blank?
      return 0 if count < tiers.min
      self.tiers.inject { |mem, n| ((n <= count and n > mem) ? n : mem) }
    end

    def achievements
      @subclasses ||= []
      @subclasses.inject([]) do |list, subclass|
        list.push(subclass, *subclass.subclasses)
      end
    end

    def triggered_on?(event)
      @triggered_on == event.to_sym
    end

    def enqueue_check!(payload)
      raise "Called abstract #{self.name}.enqueue_check!(payload)"
    end

    def grant?(*attrs)
      raise "Called abstract #{self.name}.grant?(payload)"
    end

    def display_name
      raise "Called abstract #{self.name}.display_name"
    end

    def perform(*attrs)
      user_id, new_tier, tier = self.grant?(*attrs)

      if new_tier
        Orbited.send_data("user_#{user_id.to_s}", {
          msg_class: 'achievement', achievement: self.to_s,
          name: self.display_name, description: self.description,
          tier: tier
        }.to_json)
      end
    end

    private

    def has_tiers(*tiers)
      self.tiers = tiers
    end

    def triggered_on(event)
      @triggered_on = event.to_sym
    end

    def grant_return(achieved, user = nil)
      if achieved
        puts("Granting #{self.display_name} to #{user.username}!")
        return user.id.to_s, achieved, user.tiered_achievement_count(self)
      else
        return nil, false, nil
      end
    end
  end
end
