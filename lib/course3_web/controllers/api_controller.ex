defmodule Course3Web.ApiController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials
  alias Course3.Guardian
  @rooms_per_page 12

  def directory(conn, _) do
    rooms_in =
      conn.assigns.sub["id"]
      |> Room.for_user_id()
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, _, o, ur], o.id)
      |> select([r, _, o, ur], {r.name, o.username, count("ur.*")})
      |> Repo.all()

    rooms =
      Room
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, o, ur], o.id)
      |> select([r, o, ur], {r.name, o.username, count("ur.*")})
      |> Repo.all()

    conn
    |> json(%{
      "rooms" => rooms,
      "rooms_in" => rooms_in,
      "client_id" => Application.get_env(:course3, :spotify_client_id)
    })
  end

  def exchange_authorization_code_for_refresh_and_access_tokens(conn, %{code: code}) do
    received_tokens = SpotifyAccounts.post!(
      "/api/token",
      %{
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => @redirect_url
      }
    )
    %{"id" => spotify_user_id} = SpotifyApi.get!(
      "/v1/me",
      ["Authorization": "Bearer #{received_tokens["access_token"]}"]
    )
    spotify_credentials = Map.put(received_tokens, "spotify_user_id", spotify_user_id)
    Repo.delete_all(
      from sc in SpotifyCredentials,
      where: sc.user_id == ^conn.assigns.sub["user_id"]
    )
    spotify_credentials = Repo.insert(SpotifyCredentials, spotify_credentials)
    subject = Map.put(conn.assigns.sub, "spotify_credentials", spotify_credentials)
    {:ok, token, _} = Course3.Guardian.encode_and_sign(subject)
    json conn, %{"token" => token}
  end

  # def create_room(conn, %{name: name}) do
  #   # %{"sub" => subject} = Course3.Guardian.get_claims conn
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

  # defp maybe_fetch_refreshed_token(spotify_token) do
  #   if :os.system_time(:second) - 
  #     spotify_token["inserted_at"] 
  #     |> DateTime.from_naive!("Etc/UTC") 
  #     |> DateTime.to_unix() 
  #     >= spotify_token["spotify_expires_in"] - 10 do
  #     new_token = SpotifyAccounts.post! "/api/token", 
  #     %{
  #       "grant_type" => "refresh_token",
  #       "refresh_token" => spotify_token["refresh_token"]
  #     }
  #     Map.merge(spotify_token, new_token)
  #   else
  #     spotify_token
  #   end
  # end

end
