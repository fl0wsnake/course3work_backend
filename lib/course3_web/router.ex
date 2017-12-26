defmodule Course3Web.Router do
  use Course3Web, :router

  def allow_cs conn, _params do 
    conn 
    |> Plug.Conn.put_resp_header(
      "Access-Control-Allow-Origin",
      "*"
    ) 
    |> Plug.Conn.put_resp_header(
      "Access-Control-Allow-Methods",
      "GET, POST, PATCH, PUT, DELETE, OPTIONS"
    )
    |> Plug.Conn.put_resp_header(
      "Access-Control-Allow-Headers",
      "Origin, X-Requested-With, X-Auth-Token, Content-Type, Accept"
    )
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :allow_cs
  end

  pipeline :api_protected do
    plug :accepts, ["json"]
    plug Guardian.Plug.Pipeline, 
      module: Course3.Guardian, 
      error_handler: Course3.AuthErrorHandler
    plug Guardian.Plug.VerifyHeader, key: :impersonate
    plug Course3.Plugs.FetchSpotifyCredentials
    plug :allow_cs
  end

  scope "/", Course3Web do
    pipe_through :api
    post "/register", AuthController, :register
    post "/login", AuthController, :login
    options "/register", AuthController, :allow_cs
    options "/login", AuthController, :allow_cs
  end

  scope "/", Course3Web do
    pipe_through :api_protected
    # get "/directory", ApiController, :directory
    get "/get-access-token", ApiController, :exchange_authorization_code_for_refresh_and_access_tokens
    # post "/room/create", ApiController, :create_room
    # get "/room/:id", ApiController, :room
    # put "/room/:room_id/invite/:user_id", ApiController, :invite
    # put "/room/:room_id/expel/:user_id", ApiController, :expel
  end
end
