require 'pp'

class UserMailer < ActionMailer::Base
  default :from => "\"Elite Command Comlink\" <comlink@elitecommand.net>"

  def welcome(user)
    @user = user
    mail(:to => user.email, :subject => 'Welcome, Commander')
  end

  def subscribed(user)
    @user = user
    mail(:to => user.email, :subject => "Thank you for subscribing!")
  end

  def unsubscribed(user)
    @user = user
    mail(:to => user.email, :subject => "We're sorry to see you go...")
  end

  def new_password(user, new_password)
    @user = user
    @new_password = new_password

    mail(to: user.email, subject: 'Your new password for Elite Command')
  end
  
  def new_turn(game, user)
    @game = game
    @user = user
    
    mail(:to => user.email, :subject => "It's your turn in #{game.name}!")
  end
  
  def defeated(game, user)
    @game = game
    @user = user
    
    mail(:to => user.email, :subject => "You were defeated in #{game.name}")
  end
  
  def won(game, user)
    @game = game
    @user = user
    
    mail(:to => user.email, :subject => "You won in #{game.name}!")
  end
  
  def draw(game, user)
    @game = game
    @user = user
    
    mail(:to => user.email, :subject => "#{game.name} ended in a draw!")
  end

  def turn_reminder(game, sender)
    @game = game
    @user = game.current_user
    @sender = sender

    mail(:to => game.current_user.email, :subject => "#{sender.username} wants to remind you that it's your turn in #{game.name}!")
  end

  def invite(game, invitee_email, sender_name, sender_message, existing_user = false)
    @game = game
    @sender_name = sender_name
    @sender_message = sender_message
    @existing_user = existing_user

    mail(:to => invitee_email, :subject => "#{sender_name} has invited you to a game!")
  end
  
  def forum_reply(reply, user)
    @reply = reply
    @user = user

    mail(:to => user.email, :subject => "Reply to \"#{reply.topic.name}\"")
  end

  def private_message(message)
    @message = message
    @from_user = message.sender
    @to_user = message.receiver

    mail(:to => @to_user.email, :subject => "Private message from #{@from_user.username}")
  end

  def announcement(user, subject, message)
    @user = user
    @message = message

    mail(:to => user.email, :subject => subject)
  end

  def command_error(game, command, error)
    @game = game
    @command = command
    @error = error

    mail(:to => 'c.j.vincent@gmail.com', :subject => 'CommandError!')
  end
end
