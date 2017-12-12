defmodule Course3Web.Router do
  use Course3Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_protected do
    plug :accepts, ["json"]
    plug Guardian.Plug.Pipeline, 
      module: Course3.Guardian, 
      error_handler: Course3.AuthErrorHandler
    plug Guardian.Plug.VerifyHeader, key: :impersonate
    plug Course3.Plugs.FetchSubject
  end

  scope "/", Course3Web do
    pipe_through :api
    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  scope "/", Course3Web do
    pipe_through :api_protected
    get "/directory", ApiController, :directory
    get "/get-access-token", ApiController, :exchange_authorization_code_for_refresh_and_access_tokens
    get "/create-room/:name", ApiController, :create_room
  end
end
