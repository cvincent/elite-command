class GlobalChatMessagesController < ApplicationController
  before_filter :ensure_logged_in

  def create
    params[:global_chat_message][:user_id] = current_user.id
    message = GlobalChatMessage.create(params[:global_chat_message])
    Orbited.send_data("global_chat", message.to_json_hash.merge(msg_class: 'chat_message').to_json)
    render text: 'Ok'
  end
end
