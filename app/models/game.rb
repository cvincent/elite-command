class Game
  Dir.glob('app/game_commands/*.rb').each do |command_file|
    require_dependency command_file.match(/\/([a-z_]+)\.rb/)[1]
  end

  include Mongoid::Document
  include Mongoid::Timestamps
  extend MongoidIdentityMap

  field :name, :type => String
  field :turns_played, :type => Integer, :default => 0
  field :rounds_played, :type => Integer, :default => 0
  field :players, :type => Array, :default => []
  field :units, :type => String
  field :bases, :type => Array
  field :terrain_modifiers, :type => Array
  field :player_credits, :type => Array, :default => []
  field :starting_player_count, :type => Integer
  field :status, :type => String, :default => 'started'
  field :defeated_players, :type => Array, :default => []
  field :winner, :type => String
  field :chat_log, :type => Array, :default => []
  field :command_history, type: Array, default: []
  field :player_subscriptions, :type => Array, :default => []
  field :player_peace_offers, :type => Array, :default => []
  field :player_skips, type: Array, default: []
  field :turn_started_at, :type => DateTime
  field :time_limit, :type => Integer, :default => 24.hours.to_i
  field :reminder_sent_at, :type => DateTime
  field :game_type, :type => String, :default => 'subscriber'
  field :new_player, :type => Boolean, :default => false
  field :private, type: Boolean, default: false
  field :unrated, type: Boolean, default: false
  field :allow_replays, type: Boolean, default: true

  referenced_in :map
  #references_many :users, :stored_as => :array, :inverse_of => :games

  scope :visible_to_public, lambda { where(private: false) }
  scope :player_current, lambda { |u| where(:players => u._id, :status => 'started').not_in(:defeated_players => [u._id]) }
  scope :player_lost, lambda { |u| { :where => { :defeated_players => u._id } } }
  scope :player_won,  lambda { |u| { :where => { :winner => u._id.to_s } } }
  scope :player_finished, lambda { |u| { where: { players: u._id, :status.ne => 'started' } } }
  scope :available_to_player, lambda { |u|
    where(
      'this.players.length < this.starting_player_count'
    ).not_in(
      :players => [u.try(:_id)]
    ).where(
      :status => 'started'
    )
  }

  validates_presence_of :name, :allow_nil => false, :allow_blank => false

  before_create :setup_state
  before_create :increment_map_play_count
  before_save :serialize_units
  before_save :serialize_bases
  before_save :serialize_terrain_modifiers
  before_save :serialize_command_history

  def users
    @users ||= self.players.map { |p| User.find(p) }
  end

  def defeated_users
    @defeated_users ||= self.defeated_players.map { |p| User.find(p) }
  end

  def winner_user
    @winner ||= (winner ? User.find(self.winner) : nil)
  end

  def units
    @deserialized_units ||= (self.attributes[:units] and Marshal.load(self.attributes[:units].to_s))
  end

  def units=(units_array)
    @deserialized_units = units_array
  end

  def bases
    @deserialized_bases ||= (self.attributes[:bases] and Marshal.load(self.attributes[:bases].to_s))
  end

  def bases=(bases_array)
    @deserialized_bases = bases_array
  end

  def terrain_modifiers
    @deserialized_terrain_modifiers ||= (self.attributes[:terrain_modifiers] and Marshal.load(self.attributes[:terrain_modifiers].to_s))
  end

  def terrain_modifiers=(tms_array)
    @deserialized_terrain_modifiers = tms_array
  end

  def command_history
    if self.attributes[:command_history]
      @deserialized_command_history ||= self.attributes[:command_history].map { |c| Marshal.load(c.to_s) }
    end
  end

  def command_history=(command_array)
    @deserialized_command_history = command_array
  end

  def push_command!(command)
    self.command_history << command
    Game.collection.master.collection.update(
      { '_id' => self._id },
      { '$push' => { 'command_history' => BSON::Binary.new(Marshal.dump(command)) } }
    )
  end
  
  def current_user
    return self.users[0] if self.starting_player_count == 1
    self.users[self.turns_played % (self.starting_player_count)]
  end
 
  def creator
    self.users.first
  end

  def player_subscribed?(user)
    if user.try(:email_game_updates) and u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_subscriptions[u]
    else
      false
    end
  end

  def update_player_subscription(user, sub)
    if u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_subscriptions[u] = sub
      self.modify('player_subscriptions', nil, self.player_subscriptions)
      self.save
    end
  end

  def player_offered_peace?(user)
    if u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_peace_offers[u]
    end
  end

  def update_player_peace_offer(user, peace)
    if u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_peace_offers[u] = peace
      self.modify('player_peace_offers', nil, self.player_peace_offers)
      self.save
    end
  end

  def player_skip_count(user)
    if u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_skips[u]
    end
  end

  def increment_player_skip_count(user)
    if u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_skips[u] += 1
      self.modify('player_skips', nil, self.player_skips)
    end
  end

  def reset_player_skip_count(user)
    if u = self.users.find { |u| u._id == user._id } and u = self.users.index(u)
      self.player_skips[u] = 0
      self.modify('player_skips', nil, self.player_skips)
    end
  end
  
  def add_player!(user)
    if can_add_player?(user)
      self.users << user
      self.players << user._id
      self.modify('players', nil, self.players)
      self.turn_started_at = Time.now if self.current_user == user

      idx = self.players.size

      self.units.each do |u|
        u.player_id = user._id.to_s if u.player == idx
      end

      self.bases.each do |b|
        b.player_id = user._id.to_s if b.player == idx
      end

      self.game_type = user.account_type if self.players.size == 1

      self.save
    else
      false
    end
  end

  def can_add_player?(user)
    self.status == 'started' and \
    self.players.size < self.starting_player_count and \
    !self.players.include?(user._id) and \
    (!self.creator or self.game_type == 'free' or user.account_type == 'subscriber')
  end

  def remove_player!(user)
    if can_remove_player?(user)
      self.players.delete(user._id)
      self.save
    else
      false
    end
  end

  def can_remove_player?(user)
    ['waiting_for_players', 'all_present'].include?(self.status)
  end

  def player_number_for_user(user)
    self.players.index(user._id) + 1
  end

  def user_for_player_number(num)
    self.users[num - 1]
  end

  def user_credits(user)
    self.player_credits[self.players.index(user._id)] rescue nil
  end

  def set_user_credits(user, credits)
    self.player_credits[self.players.index(user._id)] = credits
  rescue
    nil
  end

  def set_player_credits(num, credits)
    self.player_credits[num - 1] = credits
  end

  def unit_owner(u)
    return nil if u['player'] == 0
    self.users[u['player'] - 1]
  end

  def base_owner(b)
    return nil if b['player'] == 0
    self.users[b['player'] - 1]
  end

  def send_chat_message(type, message, u = nil)
    message = { :msg_class => type, :message => message, :user_id => u.try(:id) }
    message.delete(:user_id) if !u
    self.append_to_chat_log(message)
    Orbited.send_data("game_#{self.id}", message.to_json)
  end

  def send_chat_message!(type, message, u = nil)
    self.send_chat_message(type, message, u)
    self.save
  end

  def append_to_chat_log(message)
    cl = self.chat_log.dup
    cl << message
    self.modify('chat_log', nil, cl)
  end
  
  def append_to_chat_log!(message)
    self.append_to_chat_log(message)
    self.save
  end

  def can_send_reminder?
    self.can_skip? and \
    (self.reminder_sent_at.nil? or (Time.now - self.reminder_sent_at) >= self.time_limit)
  end

  def can_skip?
    self.status == 'started' and self.current_user and \
    (self.turn_started_at.nil? or (Time.now - self.turn_started_at) >= self.time_limit)
  end
  
  def unit_at(x, y, slot = nil)
    slot = nil if slot == 'null'

    self.units.each do |u|
      if u.x == x and u.y == y
        return (slot ? u.loaded_units[slot] : u)
      end
    end

    return nil
  end

  def base_at(x, y)
    self.bases.each do |b|
      return b if b.x == x and b.y == y
    end

    return nil
  end

  def capturing_at?(x, y)
    if b = base_at(x, y)
      return true if b.capture_phase
    end

    return false
  end

  def rival_units
    self.units.select do |u|
      u.player_id != self.current_user._id.to_s
    end
  end

  def terrain_at(x, y)
    t = self.terrain_modifiers.reverse.find do |tm|
      true if tm.x == x and tm.y == y
    end

    if t
      return t.terrain_name.to_sym
    else
      return self.unmodified_terrain_at(x, y).to_sym
    end
  end

  def terrain_modifier_at(x, y)
    self.terrain_modifiers.reverse.find do |tm|
      true if tm.x == x and tm.y == y
    end
  end

  def unmodified_terrain_at(x, y)
    TileTypes[self.map.tiles[y][x]]
  end

  def current_round_command_pages
    # All pages of commands starting *after* the last EndTurn command
    # which was executed by the current player
    idx = self.command_history.size - 1
    cmds = self.command_history.reverse
    ret = {}

    cmds.each do |c|
      if self.current_user and c.includes_command_class?(EndTurn) and c.user.id == self.current_user.id
        break
      else
        ret[self.command_page_at_idx(idx)] = true
      end
      idx -= 1
    end

    ret.keys.each do |k|
      ret[k] = self.command_page(k)
    end

    ret
  end

  def current_round_command_pages_json
    ret = self.current_round_command_pages
    Hash[ret.map { |k, v| [k, v.map(&:to_json_hash)] }]
  end

  def command_page(p)
    first = p * 20
    last = first + 20
    self.command_history[first...last] || []
  end

  def command_page_at_idx(i)
    (i.to_f / 20.to_f).floor
  end

  def to_json_hash
    ret = self.attributes.slice(
      :_id, :map_id, :name, :starting_player_count, :status,
      :turns_played, :rounds_played, :player_credits,
      :player_subscriptions, :player_peace_offers, :player_skips,
      :turn_started_at, :time_limit, :reminder_sent_at,
      :chat_log
    ).merge(
      :map_tiles => self.map_tiles,
      :users => self.users.map(&:to_json_hash),
      :defeated_users => self.defeated_users.map(&:to_json_hash),
      :winner_user => self.winner_user,
      :units => self.units.map(&:to_json_hash),
      :bases => self.bases.map(&:to_json_hash),
      :terrain_modifiers => self.terrain_modifiers.try(:map, &:to_json_hash) || [],
      :paged_command_history => self.current_round_command_pages_json,
      :last_command_page => self.command_page_at_idx(self.command_history.size - 1),
      :preview_img => self.map.img_medium,
      :type => self.creator ? self.game_type : 'subscriber',
      :new_player => self.new_player
    )

    ret[:turn_started_at] = ret[:turn_started_at].to_i
    ret[:reminder_sent_at] = ret[:reminder_sent_at].try(:to_i) || 0
    ret
  end

  def to_json(opts = nil)
    if opts.nil?
      to_json_hash.to_json
    else
      super
    end
  end
  
  

  protected

  def map_tiles
    self.map.tiles
  end

  def player_owner_index(p)
    self.users.to_a.index(p) + 1
  end

  def setup_state
    us = map.units.dup
    bs = map.bases.dup
    tms = map.terrain_modifiers.dup rescue []

    player_indexes = (us.map { |u| u['player'] } + bs.map { |b| b['player'] }).uniq.sort - [0]

    us = us.map do |u|
      u = Unit.new(
        u['unit_type'].to_sym,
        (u['player'] == 0 ? nil : player_indexes.index(u['player']) + 1),
        u['x'], u['y']
      )
      u.summoning_sickness = false
      u.moved = false
      u
    end

    bs = bs.map do |b|
      Base.new(
        b['base_type'].to_sym,
        (b['player'] == 0 ? 0 : player_indexes.index(b['player']) + 1),
        b['x'], b['y']
      )
    end

    tms = tms.map do |tm|
      TerrainModifier.new(tm['terrain_name'], tm['x'], tm['y'])
    end

    self.units = us
    self.bases = bs
    self.terrain_modifiers = tms
    self.starting_player_count = map.player_count
    self.command_history = []

    self.player_credits = [map.starting_credits] * map.player_count

    unless self.player_credits.empty?
      self.player_credits[0] += self.bases.select do |b|
        b.base_type == :Base and b.player == 1
      end.size * 200
    end

    self.player_subscriptions = [true] * map.player_count
    self.player_peace_offers = [false] * map.player_count
    self.player_skips = [0] * map.player_count

    self.turn_started_at = Time.now
  end
  
  def increment_map_play_count
    Map.collection.master.collection.update(
      { '_id' => self.map_id },
      { '$inc' => { play_count: 1 } }
    )
  end

  def serialize_units
    self.modify('units', nil, BSON::Binary.new(Marshal.dump(@deserialized_units))) unless @deserialized_units.nil?
  end

  def serialize_bases
    self.modify('bases', nil, BSON::Binary.new(Marshal.dump(@deserialized_bases))) unless @deserialized_bases.nil?
  end

  def serialize_terrain_modifiers
    self.modify('terrain_modifiers', nil, BSON::Binary.new(Marshal.dump(@deserialized_terrain_modifiers))) unless @deserialized_terrain_modifiers.nil?
  end

  def serialize_command_history
    unless @deserialized_command_history.nil?
      arr = @deserialized_command_history.map { |c| BSON::Binary.new(Marshal.dump(c)) }
      self.modify('command_history', nil, arr)
    end
  end
end
