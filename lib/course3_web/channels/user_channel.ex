defmodule Course3Web.UserChannel do
  use Course3Web, :channel
  import Ecto.Query
  alias Course3.Room
  alias Course3.Participation
  alias Course3.Repo
  alias Course3.SpotifyCredentials
  alias Course3Web.Endpoint
  alias Course3.Knock

  def join("user:" <> user_id, _payload, socket) do
    {user_id, _} = Integer.parse user_id
    if user_id != socket.assigns.user_id do
      {:error, %{reason: "unauthorized"}}
    else
      {:ok, socket}
    end
  end

  def handle_in("directory", _, socket) do
    reply = 
      %{
        "rooms" => Room.get_rooms(),
        "rooms_in" => Room.get_rooms_in(socket.assigns.user_id),
        "rooms_saved" => Room.get_saved_rooms(socket.assigns.user_id),
        "spotify_client_id" => Application.get_env(:course3, :spotify_client_id),
      }
    {:reply, {:ok, reply}, socket}
  end

  def handle_in("create_room", %{"name" => room_name}, %{assigns: %{user_id: user_id}}) do
    spotify_credentials = SpotifyCredentials.for_user user_id
    if spotify_credentials do
      %{body: %{"id" => room_id}} = SpotifyApi.post!(
        "/v1/users/#{spotify_credentials.spotify_user_id}/playlists",
        %{"name" => room_name},
        [
          "Authorization": "Bearer #{spotify_credentials.access_token}"
        ]
      )
      IO.inspect room_id
      %Room{}
      |> Room.changeset(
        %{
          id: room_id,
          name: room_name,
          owner_id: socket.assigns.user_id
        }
      )
      |> Repo.insert!()

      Participation
      |> struct(
        %{
          room_id: room_id,
          user_id: socket.assigns.user_id,
          is_master: false
        }
      )      
      |>
      Repo.insert!()

      broadcast! socket, "rooms", %{
        rooms: Room.get_rooms()
      }
      {:reply, :ok, socket}
    else
      {:reply, {:error, %{reason: "no authenticated spotify account"}}, socket}
    end
  end

  def handle_in("knock", %{"room_id" => room_id}, %{assigns: %{user_id: user_id}} = socket) do
      %Knock{}
      |> changeset(
        %{
          user_id: user_id, 
          room_id: room_id
        }
      )
      |> Repo.insert!()

    knocks = 
      Knock
      |> Knock.for_room(room_id)
      |> Repo.all()

    Endpoint.broadcast! "room:" <> room_id, "knocks", %{knocks: knocks}
  end

  def handle_in("auth_code_for_access_tokens", %{"code" => code, "redirect_uri" => redirect_uri}, socket) do
    %{body: received_tokens} = SpotifyAccounts.post!(
      "/api/token",
      %{
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => redirect_uri
      }
    )
    received_tokens = Course3.Utils.string_map_to_atom_map received_tokens
    IO.inspect received_tokens
    %{body: %{"id" => spotify_user_id}} = SpotifyApi.get!(
      "/v1/me",
      ["Authorization": "Bearer #{received_tokens.access_token}"]
    )
    IO.inspect spotify_user_id
    spotify_credentials = Map.merge(
      received_tokens,
      %{
        spotify_user_id: spotify_user_id,
        user_id: socket.assigns.user_id
      }
    )
    (
      from sc in SpotifyCredentials,
      where: sc.user_id == ^socket.assigns.user_id
    ) |> Repo.delete_all
    SpotifyCredentials
    |> struct(spotify_credentials)
    |> IO.inspect()
    |> Repo.insert!()
    {:noreply, socket}
  end

end
