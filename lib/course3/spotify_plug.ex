defmodule Course3.Plugs.FetchSpotifyCredentials do
  import Plug.Conn
  import Ecto.Query
  alias Course3.SpotifyCredentials
  alias Course3.Repo

  def init(options), do: options

  def call(conn, _opts) do
    %{"sub" => user_id} = Guardian.Plug.current_claims(conn, key: :impersonate)

    spotify_credentials = (
     from sc in SpotifyCredentials, 
     where: sc.user_id == ^user_id
    ) |> Repo.one()

    conn = assign conn, :user_id, user_id
    assign conn, :spotify_credentials, spotify_credentials
  end
end
