class GameAlert
  def self.new_message(message)
    {
      msg_class: 'new_message',
      thread_identifier: message.thread_identifier,
      message_id: message.id.to_s,
      sender_username: message.sender.username
    }
  end

  def self.player_turn(game)
    {
      msg_class: 'player_turn',
      game_id: game.id.to_s,
      game_name: game.name
    }
  end

  def self.over_time(game)
    {
      msg_class: 'over_time',
      game_id: game.id.to_s,
      game_name: game.name
    }
  end
end
