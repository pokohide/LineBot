require 'net/http'
require 'uri'
require 'json'

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

  desc "レシピを補完"
  task completion: :environment do
    puts "START"
    recipes = Recipe.all
    count = recipes.count
    recipes.each_with_index do |recipe, r_index|
      next if recipe.materials.count != 0 && recipe.steps.count != 0

      puts "#{(r_index+1) * 100/count}%"
      uri = URI.parse("https://evening-harbor-95566.herokuapp.com/#{recipe.rid}")
      json = Net::HTTP.get(uri)
      result = JSON.parse(json)
      r = result['recipe']

      recipe.portion = r['membernum']
      recipe.time = r['time']
      recipe.fee = r['fee']
      recipe.description = r['explanation']
      r['material'].count.times do |i|
        material = Material.new(name: r['material']['name'][i], quantity: r['material']['quantity'][i])
        material.recipe = recipe
        material.save
      end
      r['process'].each_with_index do |pro, index|
        step = Step.new(image: pro['image'], content: pro['operation'], turn: index)
        step.recipe = recipe
        step.save
      end
      recipe.save
      p recipe
    end
    puts "END"
  end
end

