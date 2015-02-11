class BuyUnit < GameCommand
  def initialize(game, user, params)
    super(game, user, params)

    @location = *@params.values_at(:x, :y)
    @unit_type = @params[:unit_type].to_sym
  end

  def execute
    require_current_player
    require_running_game
    base = require_current_player_base(*@location)

    raise CommandError.new("Base is occupied.") unless @game.unit_at(*@location).nil?
    raise CommandError.new("Base cannot build that unit.") unless base.can_build_unit_type?(@unit_type)
    raise CommandError.new("Not enough credits.") unless @game.user_credits(@user) - Unit.price_for_unit_type(@unit_type) >= 0

    raise CommandError.new("Unit not allowed in free game.") if @game.game_type == 'free' and !FreeUnitTypes.include?(@unit_type)

    create_unit(@user, @unit_type, *@location)

    unit = @game.unit_at(*@location)
    modify(unit, :movement_points, 0)
    modify(unit, :attacks, unit.attack_phases)

    player_num = @game.player_number_for_user(@user)
    modify_credits(player_num, @game.user_credits(@user) - Unit.price_for_unit_type(@unit_type))

    ActiveSupport::Notifications.instrument('ec.buy_unit', command: self)

    {}
  end

  protected

  def require_current_player_base(x, y)
    @game.base_at(x, y).tap do |b|
      raise CommandError.new("No such base.") unless b
      raise CommandError.new("Not user's base.") unless b.player_id == @user._id.to_s
    end
  end
end
