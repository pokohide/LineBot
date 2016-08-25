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
    when Line::Bot::Receive::Message
      if @user.cooking?
        case @message.content
        when Line::Bot::Message::Text
          @client.send_text(
            to_mid: @to_mid,
            text: '質問ですか'
          )
        when Line::Bot::Message::Sticker
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
      else
        case @message.content
        when Line::Bot::Message::Text
          recipes = Recipe.like(@message.content[:text])
          if recipes.count == 0
            @client.send_text(
              to_mid: @to_mid,
              text: '見つかりませんでした。'
            )
          else
            sent_recipe recipes[0]
          end
        when Line::Bot::Message::Sticker
          @client.send_text(
            to_mid: @to_mid,
            text: 'okok'
          )        
        end
      end
    end 
  end

  def sent_recipe recipe
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
      START: {
        text: 'つくる',
        link_url: "#{HOST}/api/cook?mid=#{@to_mid}&rid=#{recipe.rid}"
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

  def reply1(line_ids, keyword)
    crawler = Crawler.new(keyword)
    crawler.scrape
    3.times do |i|
      sent_recipe(line_ids, crawler.results[i])
      #rich_message(line_ids, crawler.results[i])
      #send_image(line_ids, crawler.results[i][:image])
      #send_text(line_ids, crawler.results[i][:content])
      rich_message(line_ids, crawler.results[i])
    end
  end

  def send_text(line_ids, message)
    post('/v1/events', {
        to: line_ids,
        content: {
            contentType: ContentType::TEXT,
            toType: ToType::USER,
            text: message
        },
        toChannel: TO_CHANNEL,
        eventType: EVENT_TYPE
    })
  end

  def send_image(line_ids, image)
    post('/v1/events', {
      to: line_ids,
      content: {
        contentType: ContentType::IMAGE,
        toType: ToType::USER,
        originalContentUrl: image,
        previewImageUrl: image
      },
      toChannel: TO_CHANNEL,
      eventType: EVENT_TYPE
    })
  end

  def rich_message(line_ids, recipe)
    json = {
      canvas: {
        width: 1040,
        height: 1040,
        initialScene: 'scene1'
      },
      images: {
        images1: {
          x: 0,
          y: 0,
          w: 1040,
          h: 1040
        }
      },
      actions: {
        open: {
          type: 'web',
          params: {
            linkUri: "https://line2016.herokuapp.com/api/choice?mid=#{line_ids.first}&recipe_id=#{recipe[:id]}"
          }
        },
        yes: {
          type: 'web',
          params: {
            linkUri: 'https://www.google.co.jp/#q=yes'
          }
        },
        no: {
          type: 'web',
          params: {
            linkUri: 'https://www.google.co.jp/#q=no'
          }
        }
      },
      scenes: {
        scene1: {
          listeners: [
            {
              type: 'touch',
              action: 'no',
              params: [0, 0, 520, 1040]
            },
            {
              type: 'touch',
              action: 'yes',
              params: [520, 0, 520, 1040]
            }
          ],
          draws: [
            {
              x: 0,
              y: 0,
              w: 1040,
              h: 1040,
              image: 'image1'
            }
          ]
        }
      }
    }.to_json
    Rails.logger.info({success: json})
    post('/v1/events', {
      to: line_ids,
      content: {
        contentType: ContentType::RICH,
        toType: ToType::USER,
        contentMetadata: {
          #DOWNLOAD_URL: recipe[:image],
          DOWNLOAD_URL: 'https://line2016.herokuapp.com/images',
          SPEC_REV: '1',
          ALT_TEXT: recipe[:content],
          MARKUP_JSON: json
        }
      }
    })
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
end