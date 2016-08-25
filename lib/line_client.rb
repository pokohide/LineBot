require "faraday"
require "faraday_middleware"
require "json"
require "pp"
require 'line/bot'
require "#{Rails.root}/lib/crawler"

class LineClient
  module ContentType
    TEXT = 1
    IMAGE = 2
    VIDEO = 3
    AUDIO = 4
    LOCATION = 7
    STICKER = 8
    CONTACT = 10
    RICH = 12
  end
  module ToType
    USER = 1
  end

  HOST = 'https://line2016.herokuapp.com'

  END_POINT = "https://trialbot-api.line.me"
  TO_CHANNEL = 1383378250 # this is fixed value
  EVENT_TYPE = "138311608800106203" # this is fixed value

  def initialize(client, message)
    @client = client
    @message = message
    @to_mid = message.from_mid
    @user = User.find_or_create_by(mid: @to_mid)
  end

  def reply
    case @message
    when Line::Bot::Receive::Operation
      case data.content
      when Line::Bot::Operation::AddedAsFriend
        introduce_myself
      end
    when Line::Bot::Receive::Message
      if @user.cooking?
        case @message.content
        when Line::Bot::Message::Text
          send_text '質問ですか?'
        when Line::Bot::Message::Sticker
          send_text 'ステッカー送ってきたな！'      
        end
      else
        case @message.content
        when Line::Bot::Message::Text
          if /(.+?)をつくります！！！/ =~ @message.content[:text]
            send_text "#{$1}のクッキングを開始します！"
          else
            recipes = Recipe.like(@message.content[:text])
            if recipes.count == 0
              send_text '見つかりませんでした。'
            else
              3.times do |i|
                send_recipe recipes[i]
                send_choice recipes[i]
              end
            end
          end
        when Line::Bot::Message::Sticker
          send_text 'okok'      
        end
      end
    end 
  end

  def send_recipe recipe
    @client.multiple_message.add_text(
      text: recipe.name
    ).add_image(
      image_url: recipe.image,
      preview_url: recipe.image
    ).send(
      to_mid: @to_mid
    )
  end

  def send_choice recipe
    Rails.logger.info(recipe.inspect)
    @client.rich_message.set_action(
      FOOD: {
        text: '食材',
        link_url: "#{HOST}/recipe/#{recipe.rid}/materials"
      },
      RECIPE: {
        text: 'レシピ',
        link_url: "#{HOST}/recipe/#{recipe.rid}"
      },
      COOK: {
        text: 'つくる',
        params_text: "#{recipe.name}をつくります！！！",
        type: "sendMessage",
      }
    ).add_listener(
      action: 'FOOD',
      x: 0,
      y: 0,
      width: 340,
      height: 340
    ).add_listener(
      action: 'RECIPE',
      x: 341,
      y: 0,
      width: 340,
      height: 340
    ).add_listener(
      action: 'START',
      x: 641,
      y: 0,
      width: 340,
      height: 340
    ).send(
      to_mid: @to_mid,
      image_url: "#{HOST}/images/#{recipe.rid}",
      alt_text: recipe.name
    )
  end

  def post(path, data)
    client = Faraday.new(:url => END_POINT) do |conn|
      conn.request :json
      conn.response :json, :content_type => /\bjson$/
      conn.adapter Faraday.default_adapter
      conn.proxy @proxy
    end

    res = client.post do |request|
      request.url path
      request.headers = {
          'Content-type' => 'application/json; charset=UTF-8',
          'X-Line-ChannelID' => @channel_id,
          'X-Line-ChannelSecret' => @channel_secret,
          'X-Line-Trusted-User-With-ACL' => @channel_mid
      }
      request.body = data
    end
    res
  end

  private
  def introduce_myself
    @client.send_text(
      to_mid: @to_mid,
      text: """
        料理bot登録してくれてありがとう！􀁺
        料理上手への道の第一歩を踏み出したそこのあなた􀁸
        これから一緒に料理を作っていって、料理レベルを上げていこう！✨
        上手くできたら友達に自慢できるかも？！􀂌
      """
    )
  end

  def send_text text 
    @client.send_text(
      to_mid: @to_mid,
      text: text
    )   
  end
end