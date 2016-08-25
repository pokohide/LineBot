# encoding: utf-8
require "#{Rails.root}/lib/line_client"
require "#{Rails.root}/lib/crawler"
require 'line/bot'
require 'RMagick'

module Magick
  class Draw
    # Specify text drawing font
    def font(name)
      primitive "font '#{name}'"
    end
  end
end

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
 
  def assets
    if params[:path] == 'next'
      open("#{Rails.root}/public/images/next.jpg") do |data|
        send_data(data.read, :disposition => "inline", :type => "image/jpeg")
      end
    elsif params[:path] == 'finish'
      open("#{Rails.root}/public/images/finish.jpg") do |data|
        send_data(data.read, :disposition => "inline", :type => "image/jpeg")
      end
    end
  end

  def cut
    open("#{Rails.root}/public/images/cut/#{params[:id]}.jpg") do |data|
      send_data(data.read, :disposition => "inline", :type => "image/jpeg")
    end
  end

  def yaku
    open("#{Rails.root}/public/images/yaku/#{params[:id]}.jpg") do |data|
      send_data(data.read, :disposition => "inline", :type => "image/jpeg")
    end
  end

  def image
    recipe = Recipe.find_by(rid: params[:rid])

    if recipe.main.present?
      send_data(recipe.main, :disposition => "inline", :type => "image/jpeg")
    else
      begin
        original = Magick::Image.read(recipe.image).first
        image = original.resize_to_fit(400, 400)

        # draw = Magick::Draw.new
        # draw.font(Rails.root.join('fonts', 'font.otf'))
        # 文字の影 ( 1pt 右下へずらす )
        # draw.annotate(image, 0, 0, 4, 4, recipe.name) do
          #self.font_family = "#{Rails.root}/publick/fonts/font.ttf"
        #  self.font_family = "#{Rails.root}/fonts/font.otf"
        #  self.fill      = 'black'                   # フォント塗りつぶし色(黒)
        #  self.stroke    = 'transparent'             # フォント縁取り色(透過)
        #  self.pointsize = 50                        # フォントサイズ(16pt)
        #  self.gravity   = Magick::NorthWestGravity  # 描画基準位置(左上)
        #end

        # 文字
        #draw.annotate(image, 0, 0, 5, 5, recipe.name) do
          #self.font_family = "#{Rails.root}/publick/fonts/font.ttf"
        #  self.font_family = "#{Rails.root}/fonts/font.otf"
        #  self.fill      = 'white'                   # フォント塗りつぶし色(白)
        #  self.stroke    = 'transparent'             # フォント縁取り色(透過)
        #  self.pointsize = 50                        # フォントサイズ(16pt)
        #  self.gravity   = Magick::NorthWestGravity  # 描画基準位置(左上)
        #end
      
        # 画像生成
        # image.write("temp.png")
        # image = Magick::ImageList.new("temp.png", "#{Rails.root}/public/images/choice.jpg")
        # image = image.append(true)

        choice = Magick::Image.read("#{Rails.root}/public/images/choice.jpg").first
        image.composite!(choice, Magick::SouthWestGravity, Magick::OverCompositeOp)
        #recipe.main = image.to_blob
        send_data image.to_blob
        #recipe.save
      rescue => e
        open(recipe.image) do |data|
          send_data(data.read, :disposition => "inline", :type => "image/jpeg")
        end
      end
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
