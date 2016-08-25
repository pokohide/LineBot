require "#{Rails.root}/lib/line_client"
require "#{Rails.root}/lib/crawler"
require 'line/bot'
require 'RMagick'

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

    if recipe.main.present?
      send_data(recipe.main, :disposition => "inline", :type => "image/jpeg")
    else
      original = Magick::Image.read(recipe.image).first
      image = original.resize_to_fit(1024, 9999)
      draw = Magick::Draw.new
      begin
        draw.font(Rails.root.join('app', 'public', 'fonts', 'font.ttf'))
        # 文字の影 ( 1pt 右下へずらす )
        draw.annotate(image, 0, 0, 4, 4, recipe.name) do
          #self.font_family = "#{Rails.root}/publick/fonts/font.ttf"
          self.fill      = 'black'                   # フォント塗りつぶし色(黒)
          self.stroke    = 'transparent'             # フォント縁取り色(透過)
          self.pointsize = 50                        # フォントサイズ(16pt)
          self.gravity   = Magick::NorthWestGravity  # 描画基準位置(左上)
        end

        # 文字
        draw.annotate(image, 0, 0, 5, 5, recipe.name) do
          #self.font_family = "#{Rails.root}/publick/fonts/font.ttf"
          self.fill      = 'white'                   # フォント塗りつぶし色(白)
          self.stroke    = 'transparent'             # フォント縁取り色(透過)
          self.pointsize = 50                        # フォントサイズ(16pt)
          self.gravity   = Magick::NorthWestGravity  # 描画基準位置(左上)
        end
      
        # 画像生成
        image.write("temp.png")
        image = Magick::ImageList.new("temp.png", "#{Rails.root}/public/images/choice.jpg")
        image = image.append(true)
        recipe.main = image.to_blob
        send_data image.to_blob
        recipe.save
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
