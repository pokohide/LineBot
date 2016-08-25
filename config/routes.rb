Rails.application.routes.draw do
  post '/callback' => 'webhook#callback'
  get '/search/:keyword', to: 'webhook#search'
  get '/images/:rid/:size', to: 'webhook#image'

  get '/api/cook', to: 'webhook#cook'

  get '/recipe/:rid', to: 'recipes#show'
  get '/recipe/:rid/materials', to: 'recipes#materials'
  get '/assets/:path/:size', to: 'webhook#assets'
end
