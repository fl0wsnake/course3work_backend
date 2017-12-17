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
    plug Course3.Plugs.FetchSpotifyCredentials
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
    post "/room/create", ApiController, :create_room
    get "/room/:id", ApiController, :room
    put "/room/:room_id/invite/:user_id", ApiController, :invite
    put "/room/:room_id/expel/:user_id", ApiController, :expel
  end
end
