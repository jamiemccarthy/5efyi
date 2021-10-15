Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # Almost every application defines a route for the root path ("/") at the top of this file.
  # root "articles#index"

  get "/", to: "homepage#index"
  get "/health_check", to: "health_check/health_check#index"
  get "(:ogl_name)", to: "ogl_content#show", ogl_name: OglContentController::FILENAME_REGEX
end
