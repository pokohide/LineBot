namespace :recipes do
  desc "レシピを登録する"
  task fetch: :environment do
    END_POINT = 'http://recipe.rakuten.co.jp/search/'
    url = END_POINT + ENV['key']
    url += '/' + ENV['p'] if ENV['p']
    url += '/?s=4&v=0&t=2'
    url = URI.encode(url)

    p url

    user_agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36'
    charset = nil
    html = open(url, 'User-Agent' => user_agent) do |f|
      charset = f.charset
      f.read
    end
    doc = Nokogiri::HTML.parse(html, nil, charset)
    x = doc.xpath('//div[@class="contentsBox"]/div[@class="recipeBox02"]//li/div/a')
    x.each do |n|
      link = n.attr('href')
      id = link.match(/\/(\d+)\//)[1]
      image = n.xpath('//div[@class="recipeImg"]//img').attr('src').value.sub(/\?thub=\d+/, '')
      name = n.xpath('//div[@class="recipeImg"]//img').attr('alt').value
      p name
      recipe = Recipe.new
      recipe.image = image
      recipe.name = name
      recipe.rid = id
      #p recipe
      #recipe.save
    end
  end
end
