Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post '/callback' => 'webhook#callback'
  get '/search/:keyword', to: 'webhook#search'
  get '/images/:rid/:size', to: 'webhook#image'
end
