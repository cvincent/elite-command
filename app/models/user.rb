require 'digest/md5'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  extend MongoidIdentityMap

  field :username, :type => String
  field :email, :type => String
  field :password_hash, :type => String
  field :rating, :type => Integer, :default => EloCalculator::StartingRating
  field :invite_code, :type => String
  field :invites, :type => Integer, :default => 0
  field :invited_by, :type => String, :default => nil
  field :games_won, :type => Integer, :default => 0
  field :games_lost, :type => Integer, :default => 0
  field :games_drawn, :type => Integer, :default => 0
  field :email_game_updates, :type => Boolean, :default => true
  field :email_forum_updates, :type => Boolean, :default => true
  field :email_announcements, :type => Boolean, :default => true
  field :account_type, :type => String, :default => 'subscriber'
  field :subscription_name, :type => String, :default => nil
  field :subscription_expires_after, :type => Date, :default => Date.today - 1.day
  field :spreedly_token, :type => String, :default => nil
  field :src, :type => String, :default => nil
  field :tid, :type => String, :default => nil
  field :achievements, type: Hash, default: {}

  scope :played, where('this.games_won + this.games_lost + this.games_drawn > 0')

  attr_accessor :password, :password_confirmation

  validates_format_of :username,
                      :with => /^[A-Za-z0-9_.-]{3,16}$/,
                      :message => 'must be between 3 and 16 characters (letters, numbers, "_", "-", and "." are allowed).',
                      :allow_blank => false,
                      :allow_nil => false

  validates_uniqueness_of :username,
                          :message => 'already taken.'

  validates_format_of :email,
                      :with => /^.+@.+$/, :message => 'must be valid.',
                      :allow_blank => false,
                      :allow_nil => false

  unless Rails.env.to_sym == :development
    validates_uniqueness_of :email,
                            :message => 'already taken.'
  end

  validates_length_of :password,
                      :minimum => 5,
                      :maximum => 16,
                      :message => 'must be between 5 and 16 characters.',
                      :allow_blank => false,
                      :allow_nil => false,
                      :if => proc { |me| me.new_record? or !me.password.nil? }

  validates_confirmation_of :password,
                            :message => 'and confirmation must match.'

  before_save :hash_password
  before_create :initialize_invite_code
  before_create :ensure_tid

  UUID_GENERATOR = UUID.new
  PASSWORD_SALT = 'kingcrimson666chunkybacon'

  @@current_user = nil

  def self.find_by_username_and_password(username, password)
    where(:username => username, :password_hash => password_to_hash(password)).first
  end

  def self.generate_tid
    UUID_GENERATOR.generate
  end

  def self.current
    @@current_user
  end

  def self.current=(user)
    @@current_user = user
  end

  def donations
    Donation.where(user_id: id.to_s)
  end

  def donated_monthly?
    donations.where(:created_at.gte => Time.now - 31.days).count > 0
  end

  def donated_ever?
    donations.count > 0
  end

  def achievement_count(a)
    return 0 if self.achievements.nil?
    return 0 if self.achievements[a.to_s].nil?
    return self.achievements[a.to_s]
  end

  def tiered_achievement_count(a)
    return 0 if self.achievements.nil?
    return 0 if self.achievements[a.to_s].nil?

    if a.tiered?
      a.tier_for_count(self.achievements[a.to_s])
    else
      self.achievement_count(a) > 0 ? 1 : 0
    end
  end

  def achieved!(a)
    previous_tier = self.tiered_achievement_count(a)

    self.achievements ||= {}
    self.achievements[a.to_s] ||= 0
    self.achievements[a.to_s] += 1

    User.collection.master.collection.update(
      { '_id' => self._id },
      { '$inc' => { "achievements.#{a.name}" => 1 } }
    )

    self.tiered_achievement_count(a) > previous_tier
  end

  def tiered_achievements
    self.achievements.map do |name, count|
      a = Kernel.const_get(name)
      {
        :class => a,
        tier: self.tiered_achievement_count(a)
      }
    end.sort_by { |a| a[:class].display_name }
  end

  def trophies
    @trophies ||= Trophy.where(user_id: self.id.to_s).to_a
  end

  def update_spreedly_data!
    sub = RSpreedly::Subscriber.find(self._id.to_s)

    if sub
      active_until = sub.active_until.to_date
      self.subscription_expires_after = active_until.blank? ? Date.today - 1.day : active_until + 1.day
      self.subscription_name = sub.subscription_plan_name
      self.spreedly_token = sub.token

      if sub.lifetime_subscription
        self.account_type = 'subscriber'
      elsif self.subscription_expires_after and self.subscription_expires_after >= Date.today
        self.account_type = 'subscriber'
      else
        self.account_type = 'free'
      end
    else
      self.account_type = 'free'
    end

    self.save
  end

  def update_subscription!(sub, effective)
    if sub
      self.account_type = 'subscriber'
      self.subscription_name = sub[:identifier]
      self.subscription_expires_after = effective + sub[:length] + 1.day
      UserMailer.subscribed(self).deliver rescue nil
    else
      self.account_type = 'free'
      self.subscription_name = nil
      self.subscription_expires_after = effective
      UserMailer.unsubscribed(self).deliver rescue nil
    end

    self.save
  end

  def allowed_maps
    if self.account_type == 'subscriber'
      Map.published
    elsif self.account_type == 'free'
      Map.published.free
    end
  end

  def map_allowed?(map)
    if self.account_type == 'subscriber'
      map.status == 'published'
    elsif self.account_type == 'free'
      map.status == 'published' and map.free
    end
  end

  def games
    @games ||= Game.where(:players => { :"$in" => [self._id] })
  end

  def current_games
    Game.player_current(self)
  end

  def won_games
    Game.player_won(self)
  end

  def lost_games
    Game.player_lost(self)
  end

  def finished_games
    Game.player_finished(self)
  end

  def games_played
    self.games_won + self.games_lost + self.games_drawn
  end

  include ActiveSupport::Benchmarkable

  def logger
    Rails.logger
  end

  def game_alerts
    alerts = self.games.where(status: 'started').select do |g|
      g.current_user == self or g.can_send_reminder?
    end.map do |g|
      if g.current_user == self
        GameAlert.player_turn(g)
      elsif g.can_send_reminder?
        GameAlert.over_time(g)
      end
    end

    alerts += Message.latest_unread_threads_for_user(self).map do |m|
      GameAlert.new_message(m)
    end

    alerts
  end

  def to_json_hash
    self.attributes.slice(:_id, :username, :rating)
  end

  def to_json(opts = nil)
    if opts.nil?
      to_json_hash.to_json
    else
      super
    end
  end

  protected

  def hash_password
    if self.password
      self.password_hash = User.password_to_hash(self.password)
    end
  end

  def self.password_to_hash(password)
    Digest::MD5.hexdigest(password + PASSWORD_SALT)
  end

  def initialize_invite_code
    self.invite_code = Digest::MD5.hexdigest("#{self.username}#{Time.now.to_i}#{PASSWORD_SALT}")
  end

  def ensure_tid
    self.tid = self.class.generate_tid if !self.tid
  end
end
