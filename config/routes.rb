Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post '/callback' => 'webhook#callback'
  get '/search/:keyword', to: 'webhook#search'
  #get '/images/:recipe_id/:id', to: 'webhook#image'
  get '/images/:recipe_id/:mid', to: 'webhook#image'
end
