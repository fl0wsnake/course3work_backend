defmodule Course3Web.ApiController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials
  @rooms_per_page 12
  @redirect_url "http://redirect_url.com"

  def directory(conn, _) do
    # TODO add limits and another route for complete pagination
    {subject, _} = subject_and_claims conn
    rooms_in =
      subject["userid"]
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
    {subject, _} = subject_and_claims conn
    received_tokens = SpotifyAccounts.post! "/api/token",
    %{
      "grant_type" => "authorization_code",
      "code" => code,
      "redirect_uri" => @redirect_url
    }
      # TODO should use changesets instead of this crap
      # user = User.token_changeset(%User{}, Map.merge(subject, Map.take(received_tokens, [:access_token, :refresh_token, :expires_in])))
    %{"id" => spotify_user_id} = SpotifyApi.get! "/v1/me", ["Authorization": "Bearer #{received_tokens["access_token"]}"]
    spotify_credentials = Map.put(received_tokens, "spotify_user_id", spotify_user_id)
    Repo.delete_all(SpotifyCredentials, %{user_id: subject["user_id"]})
    spotify_credentials = Repo.insert(SpotifyCredentials, spotify_credentials)
    subject = Map.put(subject, "spotify_credentials", spotify_credentials)
    user = User.changeset(%User{}, subject)
    {:ok, token, _} = Course3.Guardian.encode_and_sign(user)
    # TODO
    # Repo.update SpotifyCredentials.changeset(%SpotifyCredentials{}, subject)
    json conn, %{"token" => Course3.Guardian.encode_and_sign(subject)}
  end

  def create_room(conn, %{name: name}) do
    {subject, _} = subject_and_claims conn
    case spotify_credentials = Map.get(subject, "spotify_credentials") do
      nil ->
        conn
        |> put_status(401)

      _ ->
        case SpotifyApi.post! "/v1/users/#{spotify_credentials["spotify_user_id"]}/playlists",
          %{"name" => name},
          ["Authorization": "Bearer #{spotify_credentials["spotify_access_token"]}", "Content-Type": "application/json"] do
            {:ok, _} ->
              conn
              |> put_status(201)

          {:error, _} ->
            conn
            |> put_status(500)
          end
    end
  end

  # defp auth_token do
  #   client_id = Application.get_env(:course3, :spotify_client_id)
  #   client_secret = Application.get_env(:course3, :spotify_client_secret)
  #   Base.encode64(client_id <> ":" <> client_secret)
  # end

  defp subject_and_claims(conn) do
    claims = Course3.Guardian.get_claims conn
    resource = Course3.Guardian.get_resource conn
    IO.puts "subject_and_claims:"
    IO.inspect resource
    subject = claims["sub"]
    {subject, claims}
  end
end
