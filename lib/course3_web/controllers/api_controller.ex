defmodule Course3Web.ApiController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials

  def directory(conn, _) do
    conn
    |> json(
      %{
        "rooms" => Room.get_rooms(),
        "rooms_in" => Room.get_rooms_in(conn.assigns.user_id),
        "rooms_saved" => Room.get_saved_rooms(socket.assigns.user_id),
        "spotify_client_id" => Application.get_env(:course3, :spotify_client_id),
      }
    )
  end

end
