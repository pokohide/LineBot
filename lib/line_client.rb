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

  END_POINT = "https://trialbot-api.line.me"
  TO_CHANNEL = 1383378250 # this is fixed value
  EVENT_TYPE = "138311608800106203" # this is fixed value

  # def initialize(channel_id, channel_secret, channel_mid, request, proxy = nil)
  #   @channel_id = channel_id
  #   @channel_secret = channel_secret
  #   @channel_mid = channel_mid
  #   @proxy = proxy
  #   @request = request
  #   @client ||= Line::Bot::Client.new do |config|
  #     config.channel_id = channel_id
  #     config.channel_secret = channel_secret
  #     config.channel_mid = channel_mid
  #   end
  # end

  def initialize(client, message)
    @client = client
    @message = message
    @to_mid = message.from_mid
  end

  def reply
    case message
    when Line::Bot::Receive::Operation
      case data.content
      when Line::Bot::Operation::AddedAsFriend
        @client.send_text(
          to_mid: @to_mid,
          text: "Hello",
        )
      end
    when Line::Bot::Receive::Message
      case message.content
      when Line::Bot::Message::Text
        @client.send_text(
          to_mid: @to_mid,
          text: message.content[:text]
        )
      when Line::Bot::Message::Sticker
        @client.send_text(
          to_mid: @to_mid,
          text: 'aaaaaaaaaaaaaaaa'
        )        
      end
    end 
  end

  def sent_recipe(line_ids, recipe)
    id = recipe[:id]
    # @client.rich_message.set_action(
    #   "#{id}": {
    #     text: recipe[:content],
    #     link_url: "https://line2016.herokuapp.com/api/choice?mid=#{line_ids}&recipe_id=#{id}",
    #   }
    # ).add_listener(
    #   action: "#{id}",
    #   x: 0,
    #   y: 0,
    #   width: 520,
    #   height: 520
    # ).send(
    #   to_mid: line_ids,
    #   image_url: recipe[:image],
    #   alt_text:recipe[:content]
    # )
    Rails.logger.info({success: recipe})
    @client.send_text(
      to_mid: line_ids,
      text: recipe[:content],
    )
  end

  def reply(line_ids, keyword)
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