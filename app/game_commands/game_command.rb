class CommandError < RuntimeError; end
class IrreversibleCommand < RuntimeError; end

class GameCommand
  attr_reader :user

  def initialize(game, user, params = {})
    @game = game
    @user = user
    @params = HashWithIndifferentAccess.new(params)
    @executed = false
    @changes = []
  end

  def execute
    raise NoMethodError, 'Called abstract method GameCommand#execute'
  end

  def execute!
    ret = execute
    @game.save
    ret
  end

  def unexecute
    spcl = SpclInterpreter.new(@game)

    @changes.reverse.each do |c|
      spcl.unexecute(c)
    end
  end

  def unexecute!
    ret = unexecute
    @game.save
    ret
  end

  def includes_command_class?(klass)
    self.instance_of?(klass)
  end

  def to_json_hash
    ret = { :command_class => self.class.to_s, :user_id => @user._id.to_s, :params => @params, changes: @changes }
    ret[:ivars] = {}

    exclude = [:@game, :@user, :@params, :@subcommands]
    self.instance_variables.each do |var|
      ret[:ivars][var.to_s.gsub('@', '').to_sym] = self.instance_variable_get(var) unless exclude.include?(var)
    end

    ret
  end

  protected

  def require_player
    raise CommandError.new("User is not in the game.") unless @game.users.include?(@user)
  end

  def require_not_waiting_for_player
    raise CommandError.new("Waiting for a player to enter the game.") unless @game.current_user
  end

  def require_current_player_exceeded_time_limit
    raise CommandError.new("Current player has not exceeded time limit.") unless @game.can_skip?
  end

  def require_current_player_exceeded_skip_limit
    raise CommandError.new("Current player has not been skipped twice consecutively.") unless @game.player_skip_count(@game.current_user) >= 2
  end

  def require_current_player
    raise CommandError.new("Not user's turn.") unless @user == @game.current_user
  end

  def require_running_game
    raise CommandError.new("Game not running.") unless @game.status == 'started'
  end

  def require_current_player_unit(x, y, slot = nil)
    @game.unit_at(x, y, slot).tap do |unit|
      raise CommandError.new("No such unit.") unless unit
      raise CommandError.new("Not user's unit.") unless unit.player_id == @user._id.to_s
    end
  end

  def require_rival_base(x, y)
    @game.base_at(x, y).tap do |b|
      raise CommandError.new("No such base.") unless b

      if b.player_id and b.player_id == @user._id.to_s
        raise CommandError.new("Targeted base is friendly.")
      end
    end
  end

  def require_friendly_base(x, y)
    @game.base_at(x, y).tap do |b|
      raise CommandError.new("No such base.") unless b

      if b.player_id != @user._id.to_s
        raise CommandError.new("Targeted base is not friendly.")
      end
    end
  end

  def modify(obj, attr, val)
    type = (obj.is_a?(Unit) ? :unit : :base)
    old_val = obj.send(:"#{attr}")
    self.push_change([:modify, type, obj.x, obj.y, attr, val, old_val])
  end

  def modify_loaded_unit(transport, obj, attr, val)
    old_val = obj.send(:"#{attr}")
    self.push_change([:modify_loaded_unit, transport.x, transport.y,
                     transport.loaded_units.index(obj),
                     attr, val, old_val])
  end

  def modify_game(attr, val)
    old_val = @game.send(:"#{attr}")
    self.push_change([:modify_game, attr, val, old_val])
  end

  def modify_credits(player_num, val)
    old_val = @game.user_credits(user)
    self.push_change([:modify_credits, player_num, val, old_val])
  end

  def create_unit(user, unit_type, x, y)
    player = @game.player_number_for_user(user)
    self.push_change([:create_unit, player, user._id.to_s, unit_type, x, y])
  end

  def destroy_unit(unit)
    self.push_change([:destroy_unit, unit.x, unit.y, unit.to_json_hash])
  end

  def create_terrain_modifier(tm, x, y)
    self.push_change([:create_terrain_modifier, tm, x, y])
  end

  def destroy_terrain_modifier(tm)
    self.push_change([:destroy_terrain_modifier, tm.x, tm.y, tm.to_json_hash])
  end

  def move_unit(fx, fy, fslot, tx, ty, tslot)
    self.push_change([:move_unit, fx, fy, fslot, tx, ty, tslot])
  end

  def modify_skip_count(user, val)
    player = @game.player_number_for_user(user)
    old_val = @game.player_skip_count(user)
    self.push_change([:modify_skip_count, player, val, old_val])
  end

  def defeat_user(user)
    player = @game.player_number_for_user(user)
    self.push_change([:defeat_player, player])
  end

  def start_capture(base, user)
    modify(base, :capture_player_id, user._id.to_s)
    modify(base, :capture_player, @game.player_number_for_user(user))
    modify(base, :capture_phase, 1)
  end

  def continue_capture(base)
    modify(base, :capture_phase, base.capture_phase - 1)

    if base.capture_phase < 0
      modify(base, :player_id, base.capture_player_id)
      modify(base, :player, base.capture_player)
      modify(base, :capture_phase, nil)
      cancel_capture(base)
      true
    else
      false
    end
  end

  def cancel_capture(base)
    modify(base, :capture_phase, nil)
    modify(base, :capture_player_id, nil)
    modify(base, :capture_player, nil)
  end

  def push_change(change)
    spcl = SpclInterpreter.new(@game)
    spcl.execute(change)

    @changes << change
  end

  def marshal_dump
    ivars = {}
    exclude = [:@game, :@user, :@params]
    self.instance_variables.each do |var|
      ivars[var] = self.instance_variable_get(var) unless exclude.include?(var)
    end

    [@game._id.to_s, @user._id.to_s, @params, ivars, @changes]
  end

  def marshal_load(dumped)
    initialize(Game.find_by_identity(dumped[0].to_s), User.find_by_identity(dumped[1].to_s), dumped[2])

    dumped[3].each do |var, val|
      self.instance_variable_set(var, val)
    end

    self.instance_variable_set(:@changes, dumped[4])
  end
end
