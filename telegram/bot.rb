require File.expand_path('../config/environment', __dir__)

#require_relative "var"
require 'telegram/bot'
require 'dotenv/load'


#token = ENV["API_TOKEN"]

Telegram::Bot::Client.run(@token) do |bot|
    bot.listen do |message|
      #se o User existir, ache-o por seu telegram_id no db
      #caso não exista, crie um user registrando seu id e nome
      if User.exists?(telegram_id: message.from.id)
        user = User.find_by(telegram_id: message.from.id)
      else user = User.create(telegram_id: message.from.id, name: message.from.first_name)
      end

      #The step case is a way to define the user step with organization
      #the code could be in message.text but it's more organized this way

      case user.step
        #when user step is add, save user's bot username and set next step to description
        when "add"
          if message.text == "/cancel"
            user.step = "cancel"
            
            bot.api.send_message(chat_id: message.chat.id, text: "Bot creation canceled")
          else
          botName = user.bots.create(username: message.text)
          user.step = "description"
          user.save
          bot.api.send_message(chat_id: message.chat.id, text: "Write your bot description")
          end

        when "description"
          if message.text == "/cancel"
            user.step = "cancel"
            bot.api.send_message(chat_id: message.chat.id, text: "Bot creation canceled")
          else
          end
          new_bot = user.bots.last
          new_bot.description = message.text
          new_bot.save
          user.step = nil
          user.save
          bot.api.send_message(chat_id: message.chat.id, text: "Bot saved")

        when "delete"
          if user.bots.map{|u_bot| u_bot.username}.include?(message.text)
            Bot.find_by(username: message.text).destroy
            bot.api.send_message(chat_id: message.chat.id, text: "Bot deleted")
        else
          bot.api.send_message(chat_id: message.chat.id, text: "There is no bot with such username")
        end
        user.step = nil
        user.save
        when "search"
          bots = Bot.where("description LIKE ?", "%#{message.text}%")
          bot.api.send_message(chat_id: message.chat.id, text: "Search results:")
          if !bots.size.zero?
            bots.each do |s_bot|
              bot.api.send_message(chat_id: message.chat.id, text: "#{s_bot.username}: #{s_bot.description}")
            end
          else
            bot.api.send_message(chat_id: message.chat.id, text: "There is no bot with such name")
          end
          user.step = nil
          user.save

        when "cancel"
          user.step = nil
          
      end


      case message.text
      when "/add"
        user.step = "add"
        user.save
        bot.api.send_message(chat_id: message.chat.id, text: "Write your bot username")

      when "/delete"
        user.step = "delete"
        user.save
        arr = user.bots.map{|u_bot| u_bot.username}
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: arr)
        bot.api.send_message(chat_id: message.chat.id, text: "Pick bot to delete", reply_markup: markup)

      when "/search"
        user.step = "search"
        user.save
        bot.api.send_message(chat_id: message.chat.id, text: "Write what the bot do")
      
        when "/cancel"
        user.step = "cancel"
        user.save
      end
   end
end
