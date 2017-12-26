defmodule Course3Web.PlaylistController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials
  alias Course3.Guardian

  # plug :maybe_fetch_refreshed_token

  # def create_room(conn, _) do
  #   name = conn.body_params["name"]
  #   spotify_credentials = conn.assigns.spotify_credentials
  #   %{"id" => room_id} = SpotifyApi.post! "/v1/users/#{spotify_credentials["spotify_user_id"]}/playlists",
  #   %{"name" => name},
  #     [
  #       "Authorization": "Bearer #{spotify_credentials["spotify_access_token"]}"
  #       # "Content-Type": "application/json"
  #     ]
  #   room =
  #     %Room{}
  #     |> Room.changeset(Map.merge(
  #       conn.body_params,
  #       %{
  #         room_id: room_id,
  #         owner_id: conn.assigns.user_id
  #       }
  #     ))
  #     |> Repo.insert!()

    # conn
    # |> put_status(201)
    # |> json(room)
  # end

  # def maybe_fetch_refreshed_token(conn, _opts) do
  #   spotify_credentials = conn.assings.spotify_credentials
  #   case spotify_credentials do
  #     nil ->
  #       conn
  #       |> put_status(401)
  #       |> send_resp()
  #     _ ->
  #       assign conn, :spotify_credentials, SpotifyCredentials.refresh spotify_credentials
  #   end
  # end

end
