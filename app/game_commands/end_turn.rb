class EndTurn < GameCommand
  def initialize(game, user, params = {})
    super(game, user, params)

    @surrender = params[:surrender]
    @forced_by = params[:forced_by]
    @skipping = params[:skipping] || false
  end

  def execute
    require_current_player
    require_running_game

    unless @skipping
      modify_skip_count(@user, 0)
    end

    reset_units

    newly_defeated, survived = cull_defeated_players
    defeated_elo_change, survived_elo_change = 0

    if newly_defeated.size > 0 and survived.size > 0
      defeated_elo_change, survived_elo_change = calculate_elo(newly_defeated)

      newly_defeated.each do |u|
        elo_changes = self.defeated_rating_changes_message(u, survived, defeated_elo_change, survived_elo_change)

        if u == @user and @surrender
          if @forced_by
            by = User.find_by_identity(@forced_by)
            @game.send_chat_message(:info_message, "#{by.username} forced #{u.username} to surrender!" + elo_changes, u)
          else
            @game.send_chat_message(:info_message, "#{u.username} surrendered!" + elo_changes, u)
          end
        else
          @game.send_chat_message(:info_message, "#{u.username} was defeated!" + elo_changes, u)
        end

        UserAction.record('game_lost_' + (@game.new_player ? 'servo' : 'human'), user: u)
      end

      if @game.status == 'win'
        survived.each do |u| # Prepared for team wins
          elo_change = "<br/>New rating: #{u.rating} (+#{survived_elo_change})"
          elo_change = '' if @game.unrated

          @game.send_chat_message(:info_message, "#{u.username} was victorious!#{elo_change}", u)
          UserAction.record('game_won_' + (@game.new_player ? 'servo' : 'human'), user: u)
        end

        # This part is not prepared for team wins... should only be run for FFA matches
        @game.map.increment_win_for_player!(@game.players.map(&:to_s).index(survived[0].id.to_s))

        # And this only applies to one-on-one
        if @game.starting_player_count == 2 and !@game.unrated
          Trophy.grant!(survived[0], newly_defeated[0])
        end
      end
    end

    advance_turn
    setup_new_turn

    ActiveSupport::Notifications.instrument('ec.end_turn', command: self)

    {
      :defeated_elo_change => defeated_elo_change,
      :survived_elo_change =>  survived_elo_change
    }
  end

  def unexecute
    raise IrreversibleCommand
  end

  protected

  def cull_defeated_players
    defeated_players = []

    defeated_players << @user if @surrender

    @game.users.each do |u|
      next if @game.defeated_players.include?(u._id)
      remaining_base_count = 0
      remaining_unit_count = 0

      @game.bases.each do |b|
        if b.player_id and b.player_id.to_s == u._id.to_s
          unit = @game.unit_at(b.x, b.y)

          if !unit or (unit.player_id and unit.player_id.to_s == u._id.to_s)
            remaining_base_count += 1
          end
        end
      end

      @game.units.each do |unit|
        if unit.player_id and unit.player_id.to_s == u._id.to_s
          remaining_unit_count += 1
        end
      end

      if remaining_base_count == 0 and remaining_unit_count == 0
        defeated_players << u
        UserMailer.defeated(@game, u).deliver if @game.player_subscribed?(u) rescue nil
      end
    end

    defeated_players.each { |p| defeat_user(p) }
    remaining_players = @game.users.select { |u| !@game.defeated_players.include?(u._id) }

    if remaining_players.size == 1 and @game.users.size > 1
      modify_game(:status, 'win')
      modify_game(:winner, remaining_players[0]._id)
      begin
        UserMailer.won(@game, remaining_players[0]).deliver if @game.player_subscribed?(remaining_players[0])
      rescue
        nil
      end
    elsif remaining_players.size == 0
      modify_game(:status, 'draw')

      defeated_players.each do |u|
        begin
          UserMailer.draw(@game, u).deliver if @game.player_subscribed?(u)
        rescue
          nil
        end
      end
    elsif remaining_players.all? { |p| @game.player_offered_peace?(p) }
      modify_game(:status, 'draw')

      remaining_players.each do |u|
        begin
          UserMailer.draw(@game, u).deliver if @game.player_subscribed?(u)
        rescue
          nil
        end
      end
    end

    defeated_players.each do |u|
      @game.update_player_subscription(u, false)
    end

    return defeated_players, remaining_players
  end

  def calculate_elo(newly_defeated)
    return 0, 0 if @game.unrated
    survivors = @game.users.select { |u| !@game.defeated_players.include?(u._id) }
    elo = EloCalculator.new(newly_defeated, survivors)
    defeated_elo_change, survived_elo_change = elo.calculate!
  end

  def reset_units
    delete_units = []

    @game.units.each do |u|
      modify(u, :flank_penalty, 0)
      modify(u, :summoning_sickness, false)

      unless base = @game.base_at(u.x, u.y) and base.capture_phase
        unless u.build_phase and u.build_phase > -1
          modify(u, :movement_points, UnitDefinitions[u.unit_type][:movement_points])
          modify(u, :attacks, 0)
          modify(u, :attacked, false)
          modify(u, :healed, false)
          modify(u, :moved, false)
        end
      end

      if u.armor_type == :air and base = @game.base_at(u.x, u.y)
        if base.player > 0 and base.player != u.player
          delete_units << u
        end
      end

      u.loaded_units.each do |lu|
        modify_loaded_unit(u, lu, :flank_penalty, 0)
        modify_loaded_unit(u, lu, :movement_points, UnitDefinitions[lu.unit_type][:movement_points])
        modify_loaded_unit(u, lu, :attacks, 0)
        modify_loaded_unit(u, lu, :attacked, false)
        modify_loaded_unit(u, lu, :healed, false)
        modify_loaded_unit(u, lu, :moved, false)
      end
    end

    delete_units.each { |u| destroy_unit(u) }
  end

  def advance_turn
    loop do
      modify_game(:turns_played, @game.turns_played + 1)
      modify_game(:rounds_played, @game.rounds_played + 1) if @game.turns_played % @game.starting_player_count == 0
      break if @game.current_user.nil?
      break if @game.status == 'draw'
      break unless @game.defeated_players.include?(@game.current_user._id)
    end
  end

  def setup_new_turn
    player_idx = @game.turns_played % @game.starting_player_count

    @credits_earned = @game.bases.select do |b|
      b.base_type == :Base and b.player == player_idx + 1
    end.size * 200
    @new_credits_amount = @game.player_credits[player_idx] + @credits_earned

    modify_credits(player_idx + 1, @new_credits_amount)

    if @game.current_user
      @game.bases.each do |b|
        if b.capture_player_id and b.capture_player_id.to_s == @game.current_user._id.to_s
          neutral = b.player_id.nil?
          captured = continue_capture(b)

          if captured
            ActiveSupport::Notifications.instrument('ec.base_captured',
                                                    user_id: @game.current_user.id.to_s,
                                                    neutral: neutral)
            destroy_unit(@game.unit_at(b.x, b.y))
          end
        end
      end

      @game.units.each do |u|
        if u.build_phase and u.build_phase > -1 and u.player_id.to_s == @game.current_user._id.to_s
          modify(u, :build_phase, u.build_phase - 1)

          if u.build_phase < 0
            building = u.current_build

            modify(u, :build_phase, nil)
            modify(u, :current_build, nil)
            modify(u, :movement_points, UnitDefinitions[u.unit_type][:movement_points])
            modify(u, :attacks, 0)
            modify(u, :attacked, false)
            modify(u, :healed, false)
            modify(u, :moved, false)

            if building == :destroy
              destroy_terrain_modifier(@game.terrain_modifier_at(u.x, u.y))
            else
              create_terrain_modifier(building, u.x, u.y)
            end
          end
        end
      end

      @new_current_player_id = @game.current_user.id.to_s
    end

    modify_game(:turn_started_at, Time.now)

    if @game.status == 'started' and @game.player_subscribed?(@game.current_user)
      UserMailer.new_turn(@game, @game.current_user).deliver rescue nil
      Orbited.send_data("user_#{@game.current_user.id.to_s}", {
        msg_class: 'game_alert',
        game_alert: GameAlert.player_turn(@game)
      }.to_json)
    end
  end

  def defeated_rating_changes_message(defeated_player, survived_players, defeated_elo_change, survived_elo_change)
    str = "<br/>New rating: #{defeated_player.rating} (#{defeated_elo_change})"
    str += "<br/>Remaining players: +#{survived_elo_change} each" if survived_players.size > 1
    str = '' if @game.unrated
    str
  end
end
