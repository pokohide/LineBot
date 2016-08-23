require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'robotex'

class Crawler
  attr_reader :results
  END_POINT = 'http://recipe.rakuten.co.jp/search/'

  def initialize(keyword='')
    @keyword = keyword
    @url = URI.encode(END_POINT + keyword + '/?s=4&v=1')
    @doc = doc
    @results = []
  end

  def scrape
    @doc.xpath('//*[@class="contentsBox"]/div[@class="catePopuRank"]/ol').each do |node|
      li_inner_recipe(node)
    end
  end

  def is_allowed?
    robotex = Robotex.new
    robotex.allowed(@url)
  end

  private
  def doc
    user_agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36'
    charset = nil
    html = open(@url, 'User-Agent' => user_agent) do |f|
      charset = f.charset
      f.read
    end
    @doc = Nokogiri::HTML.parse(html, nil, charset)
  end

  def li_inner_recipe node
    node.xpath('li/div[@data-ratunit="item"]/a[@id="recipe_link"]').each do |li_node|
      image = li_node.xpath('div[@class="cateRankImage"]//img').attr('src').value
      content = li_node.xpath('div[@class="cateRankTtl"]').text
      @results.push({image: image, content: content})
    end
  end
end
