require "#{Rails.root}/lib/line_client"
require "#{Rails.root}/lib/crawler"
require 'line/bot'

class WebhookController < ApplicationController

  CHANNEL_ID = ENV['LINE_CHANNEL_ID']
  CHANNEL_SECRET = ENV['LINE_CHANNEL_SECRET']
  CHANNEL_MID = ENV['LINE_CHANNEL_MID']
  OUTBOUND_PROXY = ENV['LINE_OUTBOUND_PROXY']

  def callback
    signature = request.env['HTTP_X_LINE_CHANNELSIGNATURE']
    unless client.validate_signature(request.body.read, signature)
      error 400 do 'Bad Request' end
    end
    receive_request = Line::Bot::Receive::Request.new(request.env)
    receive_request.data.each do |message|
      c = LineClient.new(client, message)
      c.reply
    end
    render :nothing => true, status: :ok
  end
  
  def cook
    render json: {rid: params[:rid], mid: params[:mid]}
  end

  def image
    recipe = Recipe.find_by(rid: params[:rid])
    open(recipe.image) do |data|
      send_data(data.read, :disposition => "inline", :type => "image/jpeg")
    end
  end

  def search
   crawler = Crawler.new(params[:keyword])
   crawler.scrape
   render json: {results: crawler.results}
  end

  private
  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_id = CHANNEL_ID
      config.channel_secret = CHANNEL_SECRET
      config.channel_mid = CHANNEL_MID
    end
  end
end
