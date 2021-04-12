Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get '/', to: 'homepage#index'
  get '/health_check', to: 'health_check/health_check#index'
  get '(:ogl_name)', to: 'ogl_content#show'
end
