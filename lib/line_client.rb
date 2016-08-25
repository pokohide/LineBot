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
          if /次へ\(手順(\d+)へ\)/ =~ @message.content[:text]
            next_step $1.to_i
          else
            send_text '質問ですか?'
          end
        when Line::Bot::Message::Sticker
          send_text 'ステッカー送ってきたな！'      
        end
      else
        case @message.content
        when Line::Bot::Message::Text
          if /(.+?)をつくります！！！/ =~ @message.content[:text]
            send_text "#{$1}のクッキングを開始します！"
            start_cooking($1)
            next_step 0
          else
            recipes = Recipe.like(@message.content[:text])
            if recipes.count == 0
              send_text '見つかりませんでした。'
            else
              #send_recipe recipes[0]
              recipe = recipes[0]
              send_text "#{recipe.name}を作りませんか?\n所要時間は#{recipe.time}で、費用は#{recipe.fee}です！"
              send_choice recipe
            end
          end
        when Line::Bot::Message::Sticker
          send_text 'okok'      
        end
      end
    end 
  end

  # 料理開始
  def start_cooking name
    @user.cook = true
    @recipe = Recipe.find_by(name: name)
    @user.r_id = @recipe.rid
    @user.now_step = 0
    @user.save
  end

  # 次のステップへ
  def next_step num
    @recipe = Recipe.find_by(rid: @user.r_id)
    step = @recipe.steps[num]
    send_step(step)
    if_next = @recipe.steps[num + 1].present?
    @user.update(now_step: num + 1)
    next_step_button if_next
  end

  # 料理終了
  def end_cooking
    @user.cook = false
    @user.now_step = nil
    @user.r_id = nil
    @user.save
  end

  def send_step step
    c = @client.multiple_message
    if step.image.present?
      c = c.add_image(
        image_url: step.image,
        preview_url: step.image
      )
    end
    c.add_text(
      text: step.content
    ).send(
      to_mid: @to_mid
    )
  end

  # 次のステップがあるかどうか
  def next_step_button if_next
    if if_next
      @client.rich_message.set_action(
        NEXT: {
          text: "次へ(手順#{@user.now_step}へ)",
          params_text: "次へ(手順#{@user.now_step}へ)",
          type: 'sendMessage'          
        }
      ).add_listener(
        action: 'NEXT',
        x: 0,
        y: 0,
        width: 1020,
        height: 144
      ).send(
        to_mid: @to_mid,
        image_url: "#{HOST}/assets/next",
        alt_text: "次へ(手順#{@user.now_step}へ)"
      )
    else
      send_text('お疲れ様でした！')
      @client.rich_message.set_action(
        SHARE: {
          text: 'シェアしよう',
          link_url: "#{HOST}/recipe/#{recipe.rid}/materials",
          type: 'web'        
        }
      ).add_listener(
        action: 'SHARE',
        x: 0,
        y: 0,
        width: 1020,
        height: 144
      ).send(
        to_mid: @to_mid,
        image_url: "#{HOST}/assets/finish",
        alt_text: 'シェアしよう'
      )
      end_cooking
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
        link_url: "#{HOST}/recipe/#{recipe.rid}/materials",
        type: 'web'
      },
      RECIPE: {
        text: 'レシピ',
        link_url: "#{HOST}/recipe/#{recipe.rid}",
        type: 'web'
      },
      COOK: {
        text: "#{recipe.name}をつくります！！！",
        params_text: "#{recipe.name}をつくります！！！",
        type: 'sendMessage'
      }
    ).add_listener(
      action: 'FOOD',
      x: 0,
      y: 0,
      width: 300,
      height: 700
    ).add_listener(
      action: 'RECIPE',
      x: 301,
      y: 0,
      width: 300,
      height: 700
    ).add_listener(
      action: 'COOK',
      x: 601,
      y: 0,
      width: 300,
      height: 700
    ).send(
      to_mid: @to_mid,
      image_url: "#{HOST}/images/#{recipe.rid}",
      alt_text: recipe.name
    )
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