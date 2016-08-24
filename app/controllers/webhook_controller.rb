require "#{Rails.root}/lib/line_client"
require "#{Rails.root}/lib/crawler"
require 'line/bot'

class WebhookController < ApplicationController
  #protect_from_forgery with: :null_session # CSRF対策無効化

  CHANNEL_ID = ENV['LINE_CHANNEL_ID']
  CHANNEL_SECRET = ENV['LINE_CHANNEL_SECRET']
  CHANNEL_MID = ENV['LINE_CHANNEL_MID']
  OUTBOUND_PROXY = ENV['LINE_OUTBOUND_PROXY']

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end
    result = params[:result][0]
    logger.info({from_line: result})
    text_message = result['content']['text']
    from_mid =result['content']['from']

    client = LineClient.new(CHANNEL_ID, CHANNEL_SECRET, CHANNEL_MID, request, OUTBOUND_PROXY)
    res = client.reply([from_mid], text_message)

    #if res.status == 200
      logger.info({success: res})
    #else
    # logger.info({fail: res})
    #end
    render :nothing => true, status: :ok
  end

  def search
   crawler = Crawler.new(params[:keyword])
   crawler.scrape
   render json: {results: crawler.results}
  end

  private
  # LINEからのアクセスか確認.
  # 認証に成功すればtrueを返す。
  # ref) https://developers.line.me/bot-api/getting-started-with-bot-api-trial#signature_validation
  def is_validate_signature
    signature = request.headers["X-LINE-ChannelSignature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end
