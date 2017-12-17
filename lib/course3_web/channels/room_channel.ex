defmodule Course3Web.RoomChannel do
  use Course3Web, :channel
  import Ecto.Query
  alias Course3.User
  alias Course3.Repo
  alias Course3.Like
  alias Course3.Invitation
  alias Course3.Participation
  alias Course3.SpotifyCredentials

  def join("room" <> room_id, _payload, socket) do
    if User.in_room? socket.assigns.user_id, room_id do
      is_master = User.is_master? socket.assigns.user_id, room_id
      broadcast!(
        "room:#{room_id}", 
        "user_entered", 
        %{user_id: socket.assigns.user_id, is_master: is_master}
      )
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("search", %{"query" => query}, socket) do
    "room:" <> room_id = socket.topic
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    tracks = SpotifyApi.get!(
      "/v1/search?type=track&limit=8&q=#{URI.encode query}",
      ["Authorization": "Bearer #{spotify_credentials.access_token}"]
    )
    {:reply, {:ok, tracks}, socket}
  end

  def handle_in("add_track", %{"track_id" => track_id}, socket) do
    "room:" <> room_id = socket.topic
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    SpotifyApi.post!(
      "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
      ["Authorization": "Bearer #{spotify_credentials.access_token}"],
      %{"uris" => ["spotify:track:" <> track_id]}
    )
    tracks = SpotifyApi.get!("/v1/users/#{socket.assigns.user_id}/playlists/#{room_id}/tracks")
    broadcast! socket, "new_tracks", tracks
    {:noreply, socket}
  end

  def handle_in("delete_track", %{"track_id" => track_id}, socket) do
    "room:" <> room_id = socket.topic
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    Like
    |> Like.for_track(track_id, room_id)
    |> Repo.delete!()
    SpotifyApi.delete!(
      "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
      ["Authorization": "Bearer #{spotify_credentials.access_token}"],
      %{"tracks" => [%{"uri" => "spotify:track:" <> track_id}]}
    )
    tracks = SpotifyApi.get!("/v1/users/#{socket.assigns.user_id}/playlists/#{room_id}/tracks")
    broadcast! socket, "new_tracks", tracks
    {:noreply, socket}
  end

  def handle_in("like_track", %{"track_id" => track_id}, socket) do
    "room:" <> room_id = socket.topic
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    # track_rating = Like.track_rating(room_id, track_id)
    track_rating = 
      Like
      |> Like.for_track(room_id, track_id)
      |> Like.track_rating()
      |> Repo.one!()

    # %Like{
    #   room_id: room_id,
    #   user_id: socket.assigns.user_id,
    #   track_id: track_id,
    # } |> Repo.insert()

    Repo.insert(%Like{}, %{
      room_id: room_id,
      user_id: socket.assigns.user_id,
      track_id: track_id,
    })

    tracks = SpotifyApi.fetch_tracks socket.assigns.user_id, room_id
    range_start = Enum.find_index tracks, fn(track) ->
      track["id"] == track_id
    end
    insert_before = Enum.find_index tracks, fn(track) ->
      track["rating"] < track_rating
    end
    SpotifyApi.put!(
      "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
      ["Authorization": "Bearer #{spotify_credentials.access_token}"],
      %{"range_start" => range_start, "insert_before" => insert_before}
    )
    tracks = SpotifyApi.fetch_tracks socket.assigns.user_id, room_id
    broadcast! socket, "new_tracks", tracks
    {:noreply, socket}
  end

  def handle_in("unlike_track", %{"track_id" => track_id}, socket) do
    "room:" <> room_id = socket.topic
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    # track_rating = Like.track_rating(room_id, track_id)
    track_rating = 
      Like
      |> Like.for_track(room_id, track_id)
      |> Like.track_rating()
      |> Repo.one!()

    Like
    |> Like.for_track(track_id, room_id)
    |> Like.for_user(socket.assigns.user_id)
    |> Repo.delete_all()
    tracks = SpotifyApi.fetch_tracks socket.assigns.user_id, room_id
    range_start = Enum.find_index tracks, fn(track) ->
      track["id"] == track_id
    end
    insert_before = Enum.find_index tracks, fn(track) ->
      track["rating"] < track_rating
    end
    insert_before = insert_before || length tracks
    SpotifyApi.put!(
      "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
      ["Authorization": "Bearer #{spotify_credentials.access_token}"],
      %{"range_start" => range_start, "insert_before" => insert_before}
    )
    tracks = SpotifyApi.fetch_tracks socket.assigns.user_id, room_id
    broadcast! socket, "new_tracks", tracks
    {:noreply, socket}
  end

  def handle_in("invite", %{"room_id" => room_id, "user_id" => user_id, "as_master" => _as_master} = params, socket) do
    if User.is_owner? socket.assigns.user_id, room_id do
        invitation = Invitation.changeset(%Invitation{}, params)
        if User.is_master? socket.assigns.user_id, room_id do
          invitation = 
            invitation 
            |> Ecto.Changeset.change(as_master: false)
            |> Repo.insert!

          push socket, "invited", Map.take(invitation, [:room_id, :as_master])
          broadcast! "room:#{room_id}", "invited", Map.take(invitation, [:user_id, :as_master])
          {:reply, {:ok}, socket}
        else
          {:reply, {:error}, socket}
        end
    end
    # case do
    #   User.is_master? conn.assigns.user_id, room_id ->
    #     Course3.Invitation.changeset(%Invitation{}, params | "as_master" => false})
    #     |> Repo.insert!
    #     pushsocket, "invited", %{room_id: room_id}
    #     {:reply, {:ok}, socket}

    #   User.is_owner? conn.assigns.user_id, room_id ->
    #     Course3.Invitation.changeset(%Invitation{}, params)
    #     |> Repo.insert!
    #     push socket, "invited", %{room_id: room_id, as_master: true}
    #     {:reply, {:ok}, socket}

    #   _ ->
    #     {:reply, {:error}, socket}

    # end
  end

  def handle_in("user_accepted_invitation", %{"room_id" => room_id}, socket) do
    invitation = Invitation
    |> Invitation.by_user_and_room(socket.assigns.user_id, room_id)
    |> Repo.one
    if invitation do
      participation = struct Participation, Map.take(invitation, [:user_id, :room_id, :as_master])
      # participation = %Participation{
      #   user_id: socket.assigns.user_id,
      #   room_id: room_id
      # }
      # participation = if invitation.as_master do
      #   Map.put participation, :is_master, true
      # else
      #   participation
      # end
      participation = Repo.insert! participation
      Repo.delete! invitation
      broadcast! "room:#{room_id}", "user_entered", Map.take(participation, [:user_id, :is_master])
      broadcast! "room:#{room_id}", "user_invitation_ended", Map.take(participation, [:user_id])
      {:reply, {:ok}, socket}
    else
    {:reply, {:error}, socket}

    end
  end

  def handle_in("user_declined_invitation", %{"room_id" => room_id}, socket) do
    {count, _} = 
      Invitation
      |> Invitation.by_user_and_room(socket.assigns.user_id, room_id)
      |> Repo.delete_all 

    if count == 0 do
      {:reply, {:error}, socket}
    else
      broadcast! "room:#{room_id}", "user_invitation_ended", %{user_id: socket.assigns.user_id}
      {:reply, {:ok}, socket}
    end
  end

  def handle_in("kick", %{"room_id" => room_id, "user_id" => user_id}, socket) do
    if User.is_master?(socket.assigns.user_id, room_id) || User.is_owner?(socket.assigns.user_id, room_id) do
      (
        from ur in "users_rooms",
        where: ur.room_id == ^room_id,
        where: ur.user_id == ^user_id
      ) |> Repo.delete!()
      broadcast! "user:#{user_id}", "user_kicked", %{"room_id" => room_id}
      broadcast! "room:#{room_id}", "user_kicked", %{"user_id" => user_id}
      {:reply, {:ok}, socket}
    else
      {:reply, {:error}}
    end
  end

  def handle_in("leave", %{"room_id" => room_id}, socket) do
      broadcast! "room:#{room_id}", "user_left", %{"user_id" => socket.assigns.user_id}
      {:noreply, socket}
  end

  def terminate(_msg, socket) do
      broadcast! socket.topic, "user_left", %{"user_id" => socket.assigns.user_id}
      {:noreply, socket}
  end

end
