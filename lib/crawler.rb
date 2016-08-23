require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'robotex'

class Crawler
  END_POINT = 'http://recipe.rakuten.co.jp/search/'

  def initialize(keyword = '')
    @keyword = keyword
    @url = END_POINT + keyword + '/?s=4&v=1'
    logger.info({success: doc.css('title').text})
  end

  def search
    doc
  end

  private
  def is_allowed?
    robotex = Robotex.new
    robotex.allowed(@url)
  end
  def doc
    user_agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36'
    charset = nil
    html = open(@url, 'User-Agent': user_agent) do |f|
      charset = f.charset
      f.read
    end
    Nokogiri::HTML.parse(html. nil, charset)
  end
end
