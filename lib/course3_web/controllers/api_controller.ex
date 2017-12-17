defmodule Course3Web.ApiController do
  use Course3Web, :controller
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials

  # def directory(conn, _) do
  #   rooms_in =
  #     conn.assigns.user_id
  #     |> Room.participating_in()
  #     |> Room.with_owner()
  #     |> Room.with_people_count()
  #     |> group_by([r, _, o, ur], o.id)
  #     |> select([r, _, o, ur], {r.name, o.username, count("ur.*")})
  #     |> Repo.all()

  #   rooms_invited_in =
  #     conn.assigns.user_id
  #     |> Room.invited_in()
  #     |> Room.with_owner()
  #     |> Room.with_people_count()
  #     |> group_by([r, _, o, ur], o.id)
  #     |> select([r, _, o, ur], {r.name, o.username, count("ur.*")})
  #     |> Repo.all()

  #   rooms =
  #     Room
  #     |> Room.with_owner()
  #     |> Room.with_people_count()
  #     |> group_by([r, o, ur], o.id)
  #     |> select([r, o, ur], {r.name, o.username, count("ur.*")})
  #     |> Repo.all()

  #   conn
  #   |> json(%{
  #     "rooms" => rooms,
  #     "rooms_in" => rooms_in,
  #     "rooms_invited_in" => rooms_invited_in,
  #     "client_id" => Application.get_env(:course3, :spotify_client_id)
  #   })
  # end

  def exchange_authorization_code_for_refresh_and_access_tokens(conn, %{"code" => code, "redirect_url" => redirect_url}) do
    received_tokens = SpotifyAccounts.post!(
      "/api/token",
      %{
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => Application.get_env(:course3, redirect_url)
      }
    )
    %{"id" => spotify_user_id} = SpotifyApi.get!(
      "/v1/me",
      ["Authorization": "Bearer #{received_tokens["access_token"]}"]
    )
    spotify_credentials = Map.put(received_tokens, "spotify_user_id", spotify_user_id)
    (
      from sc in SpotifyCredentials,
      where: sc.user_id == ^conn.assigns.user_id
    ) |> Repo.delete_all
    Repo.insert(SpotifyCredentials, spotify_credentials)
    put_status conn, 201
  end

  def room(conn, %{"id" => room_id}) do
    if User.in_room? conn.assigns.user_id, room_id do

      room =
        Room
        |> Repo.get!(room_id)
        |> preload([participants: :username])
        |> preload([invited_users: :username])

      tracks = SpotifyApi.get!("/v1/users/#{room.owner_id}/playlists/#{room.id}/tracks")

      # tracks =
      #   Track
      #   |> Track.from_room(room_id)
      #   |> select([s], "s.*")
      #   |> Repo.all()

      # participants =
      #   User
      #   |> User.from_room(room_id)
      #   |> select([u], {u.name})
      #   |> Repo.all()

      # invited =
      #   User
      #   |> User.invited_in_room?(room_id)
      #   |> select([u], {u.name})
      #   |> Repo.all()

        # json conn, %{
        #   "tracks" => tracks,
        #   "participants" => participants,
        #   "invited" => invited
        # }

      

      json(conn, Map.put(room, :tracks, tracks))
    else
      put_status conn, 401
    end
  end

end
