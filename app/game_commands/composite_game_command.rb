class CompositeGameCommand < GameCommand
  def initialize(game, user, params = {})
    super(game, user, params)
    @subcommands = []
  end

  def <<(subcommand)
    @subcommands << subcommand
  end

  def execute
    game_round = @game.rounds_played

    @subcommands.map do |sc|
      if ![EndTurn, CompositeGameCommand, RemindPlayer, SkipPlayer].include?(sc.class)
        UserAction.record('game_action_' + game_round.to_s, user: @user)
      elsif sc.class == EndTurn
        UserAction.record('game_ended_turn_' + game_round.to_s, user: @user)
      end

      ret = sc.execute

      if @game.status != 'started'
        UserAction.record('game_ended', user: @user)
      end

      ret
    end
  end

  def unexecute
    @subcommands.reverse.map do |sc|
      sc.unexecute
    end
  end

  def includes_command_class?(klass)
    @subcommands.any? { |sc| sc.includes_command_class?(klass) }
  end

  def to_json_hash
    super.merge(
      :subcommands => @subcommands.map(&:to_json_hash)
    )
  end
end
