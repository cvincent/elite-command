namespace :migrate do
  desc "Convert games from pre-Sniper release to be compatible."
  task :old_games_to_new => :environment do
    save = ENV['save']

    Game.all.each do |g|
      if !g.attributes[:units].is_a?(String)
        units_by_location = {}
        units = []
        bases = []
        chat_log = []

        g.attributes[:units].each do |u|
          units << Unit.new(
            u['unit_type'].to_sym, u['player'], u['x'], u['y'],
            u['health'], u['movement_points'],
            u['attacks'], u['flank_penalty']
          )
          units.last.player_id = g.players[u['player'] - 1]
          units.last.player_id = units.last.player_id.to_s if units.last.player_id
          units_by_location[[u['x'], u['y']]] = u
        end

        g.attributes[:bases].each do |b|
          u = units_by_location[[b['x'], b['y']]]

          bases << Base.new(
            b['base_type'].to_sym, b['player'], b['x'], b['y'],
            b['capturing'] || nil, (b['capturing'] and u ? g.players[u['player'] - 1] : nil)
          )

          if b['player'] != 0
            bases.last.player_id = g.players[b['player'] - 1]
            bases.last.player_id = bases.last.player_id.to_s if bases.last.player_id
          end

          if u and b['capturing']
            bases.last.capture_player = u['player']
            bases.last.capture_player_id = g.players[u['player'] - 1]
            bases.last.capture_player_id = bases.last.capture_player_id.to_s if bases.last.capture_player_id
          end
        end

        g.chat_log.each do |msg|
          if msg['type'].to_sym == :new_player
            u = User.find(msg['user_id'])
            chat_log << { :msg_class => :new_player, :user => u.to_json_hash }
            chat_log << { :msg_class => :info_message, :message => "#{u.username} joined.", :user_id => u._id }
          elsif msg['type'].to_sym == :chat
            u = User.find(msg['user_id'])
            chat_log << { :msg_class => :chat_message, :message => msg['message'], :user_id => u._id }
          elsif msg['type'].to_sym == :player_status
            u = User.find(msg['user_id'])
            chat_log << { :msg_class => :info_message, :message => msg['message'], :user_id => u._id }
          end
        end

        g.units = units
        g.bases = bases
        g.chat_log = chat_log
        g.command_history = []

        if save
          puts 'saving!'
          g.save
        else
          puts 'dry run'
        end
      end
    end
  end

  desc "Fix for Sniper migration above."
  task :fix_sniper_migration => :environment do
    Game.all.each do |g|
      g.bases = g.bases.map do |b|
        if b.player == 0
          b.player_id = nil
        end

        b
      end

      g.save
      puts '.'
    end
  end

  desc "Change Marines to Rangers"
  task :marines_to_rangers => :environment do
    Game.all.each do |g|
      g.units = g.units.map do |u|
        if u.unit_type == :Marine
          u.unit_type = :Ranger
        end

        u
      end

      g.save
      puts '.'
    end
  end

  desc "Force terrain under bases to be special base terrain type"
  task :base_terrain => :environment do
    Map.all.each do |m|
      m.save
    end
  end

  desc "Reverse double defeated users."
  task :undo_double_defeats => :environment do
    Game.all.each do |g|
      cl = g.chat_log.dup
      known_defeated = []

      cl.delete_if do |msg|
        if msg['msg_class'] and msg['msg_class'].to_sym == :info_message and (msg['message'] =~ /surrendered!/ or msg['message'] =~ /was defeated!/)
          uid = msg['user_id'].to_s

          if known_defeated.include?(uid)
            false_elo_change = msg['message'].match(/\((-[0-9]+)\)/)[1].to_i
            u = User.find(uid)
            u.update_attributes(:rating => u.rating - false_elo_change, :games_lost => u.games_lost - 1)
            true
          else
            known_defeated << uid
            false
          end
        end
      end

      g.chat_log = cl
      g.save
    end
  end

  desc "Mark maps as official."
  task :mark_official_maps => :environment do
    Map.all.each do |m|
      m.official = true
      m.save
    end
  end

  desc "Add peace offers array to all games."
  task :peace_offers => :environment do
    Game.all.each do |g|
      if g.player_peace_offers.nil? or g.player_peace_offers.empty?
        g.player_peace_offers = [false] * g.starting_player_count
        g.save
      end
    end
  end

  desc "Set initial #game_type for every game."
  task :game_types => :environment do
    Game.all.each do |g|
      g.game_type = g.creator.account_type
      g.save
    end
  end

  desc "Add tid to all Users and UserActions"
  task :tids => :environment do
    User.all.each do |u|
      u.send(:ensure_tid)
      u.save
    end

    UserAction.where(:user_id.nin => [nil, '']).each do |ua|
      u = User.find(ua.user_id.to_s)
      ua.user_tid = u.tid
      ua.save
    end
  end

  desc "Add New Players forum"
  task :new_players_forum => :environment do
    Forum.create(
      name: 'New Players',
      description: 'A place for new players to introduce themselves.',
      position: 5
    )
  end

  desc "Add TomServo user"
  task :tom_servo_user => :environment do
    User.create!(:username => 'TomServo', :password => 'crowtrobot86', :password_confirmation => 'crowtrobot86', :email => 'comlink@elitecommand.net')
  end

  desc "Add retroactive UserActivations from UserActions"
  task :user_activations => :environment do
    UserActivation.delete_all
    UserAction.all.each do |ua|
      ua.send(:record_user_activation, true)
    end
  end

  desc "Add Bugs & Feature Requests forum"
  task :bug_forum => :environment do
    Forum.create(
      name: 'Bugs and Feature Requests',
      description: 'Spot a bug? Have an idea for a new feature? Post it here.',
      position: 20
    )
  end

  desc "Fix Map preview image URLs"
  task :map_preview_image_urls => :environment do
    Map.all.each do |m|
      if m.img_medium =~ /codeisdangerous.s3-website-us-east-1/
        m.img_medium = m.img_medium.gsub('codeisdangerous.s3-website-us-east-1', 's3')
        m.img_medium = m.img_medium.gsub('/production', '/codeisdangerous/production')
        m.img_full = m.img_full.gsub('codeisdangerous.s3-website-us-east-1', 's3')
        m.img_full = m.img_full.gsub('/production', '/codeisdangerous/production')
      end
    end
  end

  desc "Set email_announcements to true for all users"
  task :email_announcements_flag => :environment do
    User.all.each do |u|
      u.email_announcements = true
      u.save
    end
  end

  desc "Update command_history serialization format"
  task :update_command_history => :environment do
    Game.all.each do |g|
      next if g.attributes[:command_history].empty?
      next if g.attributes[:command_history].is_a?(Array)
      g.command_history = Marshal.load(StringIO.new(g.attributes[:command_history]))
      g.save
    end
  end

  desc "Set default player_skips array for all Games"
  task :player_skips => :environment do
    Game.all.each do |g|
      g.player_skips = [0] * g.map.player_count
      g.save
    end
  end

  desc "Initialize map play counts"
  task :map_play_counts => :environment do
    Map.all.each do |m|
      m.play_count = Game.where(map_id: m.id).count
      m.save
    end
  end

  desc "Initialize user achievements"
  task :achievements => :environment do
    User.all.each do |u|
      u.achievements = {}
      u.save
    end
  end

  desc "Initialize map win counts"
  task :map_ffa_win_counts => :environment do
    Map.published.each do |m|
      m.send(:initialize_ffa_win_count_on_publication, true)
      m.save
    end

    Game.where(status: 'win').each do |g|
      idx = g.players.map(&:to_s).index(g.winner.to_s)
      g.map.increment_win_for_player!(idx)
    end
  end

  desc "Make all current games rated"
  task :unrated_games => :environment do
    Game.all.each do |g|
      g.unrated = false
      g.save
    end
  end
end
