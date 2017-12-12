defmodule Course3Web.RoomManagementController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials
  alias Course3.Guardian
  @redirect_url "http://redirect_url.com"

  plug :maybe_fetch_refreshed_token

  # def create_room(conn, %{name: name}) do
  #   # %{"sub" => subject} = Course3.Guardian.get_claims conn
  #   subject = conn.assigns.sub
  #   case spotify_credentials = Map.get(subject, "spotify_credentials") do
  #     nil ->
  #       conn
  #       |> put_status(401)
  #     _ ->
  #       # spotify_credentials = maybe_fetch_refreshed_token spotify_credentials
  #       SpotifyApi.post! "/v1/users/#{spotify_credentials["spotify_user_id"]}/playlists",
  #       %{"name" => name},
  #       ["Authorization": "Bearer #{spotify_credentials["spotify_access_token"]}", "Content-Type": "application/json"]
  #       conn
  #       |> put_status(201)
  #   end
  # end

  def create_room(conn, %{name: name}) do
    spotify_credentials = conn.assigns.sub["spotify_credentials"]
    SpotifyApi.post! "/v1/users/#{spotify_credentials["spotify_user_id"]}/playlists",
    %{"name" => name},
      [
        "Authorization": "Bearer #{spotify_credentials["spotify_access_token"]}",
        "Content-Type": "application/json"
      ]
    conn
    |> put_status(201)
  end

  def maybe_fetch_refreshed_token(conn, _opts) do
    subject = conn.assigns.sub
    case spotify_credentials = Map.get(subject, "spotify_credentials") do
      nil ->
        conn
        |> put_status(401)
        |> send_resp()

      _ ->
        spotify_credentials = if :os.system_time(:second) - spotify_credentials["inserted_at"] |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix() >= spotify_credentials["spotify_expires_in"] - 10 do
            new_credentials = SpotifyAccounts.post! "/api/token",
            %{
              "grant_type" => "refresh_token",
              "refresh_token" => spotify_credentials["refresh_token"]
            }
            Map.merge(spotify_credentials, new_credentials)
        else
          spotify_credentials
        end
        assign conn, :sub, %{subject | spotify_credentials: spotify_credentials}
    end
  end
end
