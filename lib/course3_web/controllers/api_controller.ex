defmodule Course3Web.ApiController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials

  def directory(%{assigns: %{user_id: user_id}}, conn, _) do
    conn
    |> json(
      %{
        "rooms" => Room.get_rooms(user_id),
        "rooms_in" => Room.get_rooms_in(conn.assigns.user_id),
        "spotify_client_id" => Application.get_env(:course3, :spotify_client_id),
      }
    )
  end

end
