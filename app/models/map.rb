class Map
  include Mongoid::Document
  include Mongoid::Timestamps

  EditorTileTypes = TileTypes - [:base, :airfield, :seaport, :road, :bridge]

  field :name, :type => String
  field :description, :type => String, :default => ''
  field :tiles, :type => Array, :default => []
  field :bases, :type => Array, :default => []
  field :units, :type => Array, :default => []
  field :terrain_modifiers, :type => Array, :default => []
  field :starting_credits, :type => Integer, :default => 0
  field :status, :type => String, :default => 'unpublished'
  field :img_full, :type => String, :default => nil
  field :img_medium, :type => String, :default => nil
  field :user_id, :type => String, :default => nil
  field :official, :type => Boolean, :default => false
  field :free, :type => Boolean, :default => false
  field :play_count, type: Integer, default: 0
  field :ffa_win_count, type: Array, default: []

  scope :published, where(:status => 'published')
  scope :unpublished, where(:status => 'unpublished')
  scope :official, where(:official => true)
  scope :free, where(:free => true)

  validates_presence_of :name, :allow_nil => false
  validates_length_of :name, :minimum => 0, :maximum => 32
  validates_length_of :description, :minimum => 0, :maximum => 512
  validates_numericality_of :starting_credits, greater_than_or_equal_to: 0, only_integer: true

  before_create :initialize_terrain
  before_save :ensure_tiles_under_bases
  before_save :trim_tiles_on_publication
  before_save :initialize_ffa_win_count_on_publication
  before_save :notify_publication

  attr_accessor :tiles_width, :tiles_height, :fill_terrain

  def user
    if self.user_id
      @user ||= User.find(self.user_id)
    else
      @user ||= User.where(:username => 'dris').first
    end
  end

  def tiles_width
    @tiles_width ||= 20
  end

  def tiles_height
    @tiles_height ||= 20
  end

  def fill_terrain
    @fill_terrain ||= :sea
  end
  
  def player_count
    self.bases = [] if self.bases.nil?
    self.units = [] if self.units.nil?
    ((self.bases.map { |b| b['player'] } + self.units.map { |u| u['player'] }).uniq - [0]).size
  end

  def tiles_hash
    if !@tiles_hash
      @tiles_hash = {}

      self.tiles.each_with_index do |row, y|
        row.each_with_index do |tile_index, x|
          @tiles_hash[[x, y]] = tile_index
        end
      end
    end

    @tiles_hash
  end

  def air_units?
    self.bases.any? { |b| b['base_type'].to_sym == :Airfield }
  end

  def sea_units?
    self.bases.any? { |b| b['base_type'].to_sym == :Seaport }
  end

  def increment_win_for_player!(player_idx)
    if self.player_count > 0
      self.ffa_win_count[player_idx] += 1
      self.save
    end
  end

  protected

  def initialize_terrain
    if self.tiles.empty?
      self.tiles = [[TileTypes.index(fill_terrain.to_sym)] * tiles_width.to_i] * tiles_height.to_i
    end
  end

  def ensure_tiles_under_bases
    ts = self.tiles.dup
    self.bases.each do |b|
      ts[b['y']][b['x']] = TileTypes.index(b['base_type'].to_s.downcase.to_sym)
    end
    self.modify('tiles', nil, ts)

    self.tiles = self.tiles.map { |row| row.map(&:to_i) }
  end

  def trim_tiles_on_publication
    if self.status_changed? and self.status == 'published'
      # Start with bottom rows
      (self.tiles.size - 1).downto(0) do |i|
        if tiles[i].all? { |t| TileTypes[t.to_i] == :void }
          tiles.pop
        else
          break
        end
      end

      # Now the right columns
      (self.tiles[0].size - 1).downto(0) do |i|
        if tiles.all? { |row| TileTypes[row.last.to_i] == :void }
          tiles.each_with_index do |row, i|
            tiles[i].pop
          end
        else
          break
        end
      end
    end
  end

  def initialize_ffa_win_count_on_publication(force = false)
    if force or (self.status_changed? and self.status == 'published')
      self.ffa_win_count = [0] * self.player_count
    end
  end

  def notify_publication
    if self.status_changed? and self.status == 'published'
      ActiveSupport::Notifications.instrument('ec.map_published', map: self)
    end
  end
end
