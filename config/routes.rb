Rails.application.routes.draw do
  post '/callback' => 'webhook#callback'
  get '/search/:keyword', to: 'webhook#search'
  get '/images/:rid/:size', to: 'webhook#image'

  get '/recipe/:rid', to: 'recipes#show'
  get '/recipe/:rid/materials', to: 'recipes#materials'
end
