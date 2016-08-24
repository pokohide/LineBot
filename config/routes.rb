Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post '/callback' => 'webhook#callback'
  get '/search/:keyword', to: 'webhook#search'
  #get '/images/:recipe_id/:id', to: 'webhook#image'
  get '/images/:id' => redirect('http://jp.rakuten-static.com/recipe-space/d/strg/ctrl/3/bdbe6b67ee1fb53998143b0dc1b2e201f4f09dd7.82.2.3.2.jpg', status: 200)
end
