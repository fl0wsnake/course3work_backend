defmodule Course3Web.RoomChannel do
  use Course3Web, :channel
  import Ecto.Query
  alias Course3.User
  alias Course3.Room
  alias Course3.Repo
  alias Course3.Like
  alias Course3.Knock
  alias Course3.Participation
  alias Course3.SpotifyCredentials
  alias Course3Web.Endpoint

  def join("room:" <> room_id = room_topic, _payload, %{assigns: %{user_id: user_id}} = socket) do
    user = Repo.get!(User, user_id)
    if User.in_room? user_id, room_id do
      is_master = User.is_master? user_id, room_id
      Endpoint.broadcast!(
        room_topic,
        "user_entered",
        %{
          state: %{
            participants: User.users_from_room(room_id)
          }
        }
      )
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("room", _, %{assigns: %{user_id: _user_id}, topic: "room:" <> room_id} = socket) do
      room = (
        from r in Room,
        where: r.id == ^room_id,
        preload: [:owner, :participants, :knocked_users]
      )
      |> Repo.one!()

      {:reply, {:ok, room}, socket}
  end

  def handle_in("tracks", _, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id} = socket) do
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    tracks = Track.fetch_tracks user_id, room_id, spotify_credentials
    {:reply, {:ok, %{tracks: tracks}}, socket}
  end

  def handle_in("search", %{"query" => query}, %{assigns: %{user_id: _user_id}, topic: "room:" <> room_id} = socket) do
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    %{body: tracks} = SpotifyApi.get!(
      "/v1/search?type=track&limit=8&q=#{URI.encode query}",
      SpotifyApi.authorization(spotify_credentials)
    )
    {:reply, {:ok, tracks}, socket}
  end

  def handle_in("add_track", %{"track_id" => track_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id = room_topic} = socket) do
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    tracks = Track.fetch_tracks user_id, room_id, spotify_credentials
    if Enum.any?(tracks, fn track -> track["id"] == track_id end) do
      {:reply, {:error, "track already exists in this playlist"}}
    else
      SpotifyApi.post!(
        "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
        %{"uris" => ["spotify:track:" <> track_id]},
        SpotifyApi.authorization(spotify_credentials)
      )
      Endpoint.broadcast!(
        room_topic,
        "added_track",
        %{
          user_id: user_id,
          track_id: track_id,
          state: %{
            tracks: Track.fetch_tracks(user_id, room_id, spotify_credentials)
          }
        }
      )
      {:noreply, socket}
    end
  end

  def handle_in("delete_track", %{"track_id" => track_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id = room_topic} = socket) do
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    if User.is_owner?(user_id, room_id) || User.is_master?(user_id, room_id) do
      Like
      |> Like.for_track(track_id, room_id)
      |> Repo.delete_all()
      SpotifyApi.request!(
        :delete,
        "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
        %{"tracks" => [%{"uri" => "spotify:track:" <> track_id}]},
        SpotifyApi.authorization(spotify_credentials)
      )
      Endpoint.broadcast!(
        room_topic,
        "deleted_track",
        %{
          user_id: user_id,
          track_id: track_id,
          state: %{
            tracks: Track.fetch_tracks(user_id, room_id, spotify_credentials)
          }
        }
      )
      {:noreply, socket}
    else
      {:reply, {:error, :unauthorized}}
    end
  end

  def handle_in("like_track", %{"track_id" => track_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id = room_topic} = socket) do
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    track_rating =
      Like
      |> Like.for_track(track_id, room_id)
      |> Like.track_rating()
      |> Repo.one!()

    %Like{}
    |> Like.changeset(%{
      room_id: room_id,
      user_id: user_id,
      track_id: track_id,
    })
    |> Repo.insert!()
    tracks = Track.fetch_tracks user_id, room_id, spotify_credentials
    range_start = Enum.find_index tracks, fn(track) ->
      track["id"] == track_id
    end
    insert_before = Enum.find_index tracks, fn(track) ->
      track["rating"] < track_rating
    end
    SpotifyApi.put!(
      "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
      %{"range_start" => range_start, "insert_before" => insert_before},
      SpotifyApi.authorization(spotify_credentials)
    )
    Endpoint.broadcast!(
      room_topic,
      "liked_track",
      %{
        user_id: user_id,
        track_id: track_id,
        state: %{
          tracks: Track.fetch_tracks(user_id, room_id, spotify_credentials)
        }
      }
    )
    {:noreply, socket}
  end

  def handle_in("unlike_track", %{"track_id" => track_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id = room_topic} = socket) do
    spotify_credentials = SpotifyCredentials.owner_credentials_for_room room_id
    track_rating =
      Like
      |> Like.for_track(track_id, room_id)
      |> Like.track_rating()
      |> Repo.one!()
    Like
    |> Like.for_track(track_id, room_id)
    |> Like.for_user(user_id)
    |> Repo.delete_all()
    tracks = Track.fetch_tracks user_id, room_id, spotify_credentials
    range_start = Enum.find_index tracks, fn(track) ->
      track["id"] == track_id
    end
    insert_before = Enum.find_index tracks, fn(track) ->
      track["rating"] < track_rating
    end
    insert_before = insert_before || length tracks
    SpotifyApi.put!(
      "/v1/users/#{spotify_credentials.spotify_user_id}/playlists/#{room_id}/tracks",
      %{"range_start" => range_start, "insert_before" => insert_before},
      SpotifyApi.authorization(spotify_credentials)
    )
    Endpoint.broadcast!(
      room_topic,
      "unliked_track",
      %{
        user_id: user_id,
        track_id: track_id,
        state: %{
          tracks: Track.fetch_tracks(user_id, room_id, spotify_credentials)
        }
      }
    )
    {:noreply, socket}
  end

  def handle_in("let_user_in", %{"user_id" => user_to_let_in_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id} = socket) do
    if User.is_master?(user_id, room_id) || User.is_owner?(user_id, room_id) do
      if Knock.has_knocked(user_to_let_in_id, room_id) do
        %Participation{}
        |> Participation.changeset(
          %{
            user_id: user_to_let_in_id,
            room_id: room_id
          }
        )
        |> Repo.insert!()
        Knock
        |> Knock.by_user_and_room(user_to_let_in_id, room_id)
        |> Repo.delete!()
        Endpoint.broadcast!(
          "user:#{user_to_let_in_id}",
          "user_was_let_in",
          %{
            room_id: room_id,
            by_user: user_id,
            state: %{
              rooms: Room.get_rooms(user_id),
              rooms_in: Room.get_rooms(user_id)
            }
          }
        )
        Endpoint.broadcast!(
          "room:#{room_id}",
          "user_was_let_in",
          %{
            user_id: user_to_let_in_id,
            by_user: user_id,
            state: %{
              knocked_users: User.users_knocked_in_room(room_id),
              participants: User.users_from_room(room_id)
            }
          }
        )
        {:reply, :ok, socket}
      else
        {:reply, {:error, %{reason: :wrong_input}}, socket}
      end
    else
      {:reply, {:error, %{reason: :unauthorized}}, socket}
    end
  end

  def handle_in("not_let_user_in", %{"user_id" => user_to_not_let_in_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id} = socket) do
    if User.is_master?(user_id, room_id) || User.is_owner?(user_id, room_id) do
      if Knock.has_knocked(user_id, room_id) do
        Knock
        |> Knock.by_user_and_room(user_id, room_id)
        |> Repo.delete!()
        Endpoint.broadcast!(
          "user:#{user_to_not_let_in_id}",
          "user_was_not_let_in",
          %{
            room_id: room_id,
            by_user: user_id,
            state: %{
              rooms: Room.get_rooms(user_id),
            }
          }
        )
        Endpoint.broadcast!(
          "room:#{room_id}",
            "user_was_not_let_in",
            %{
              user_id: user_to_not_let_in_id,
              by_user: user_id,
              state: %{
                knocked_users: User.users_knocked_in_room(room_id),
              }
            }
        )
        {:reply, :ok, socket}
      else
        {:reply, {:error, %{reason: :wrong_input}}, socket}
      end
    else
      {:reply, {:error, %{reason: :unauthorized}}, socket}
    end
  end

  def handle_in("kick", %{"user_id" => user_to_kick_id}, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id} = socket) do
    if User.is_master?(user_id, room_id) || User.is_owner?(user_id, room_id) do
      if User.in_room? user_to_kick_id, room_id do
        (
          from ur in "users_rooms",
          where: ur.room_id == ^room_id,
          where: ur.user_id == ^user_to_kick_id
        ) |> Repo.delete!()
        Endpoint.broadcast!(
          "user:#{user_to_kick_id}",
          "user_was_kicked",
          %{
            room_id: room_id,
            by_user: user_id,
            state: %{
              rooms_in: Room.get_rooms_in(user_to_kick_id)
            }
          }
        )
        Endpoint.broadcast!(
          "room:#{room_id}",
          "user_was_kicked",
          %{
            user_id: user_to_kick_id,
            by_user: user_id,
            state: %{
              participants: User.users_from_room(room_id)
            }
          }
        )
        {:reply, :ok, socket}
      else
        {:reply, {:error, %{reason: :wrong_input}}, socket}
      end
    else
      {:reply, {:error, %{reason: :unauthorized}}, socket}
    end
  end

  def handle_in("leave", _, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id} = socket) do
    Endpoint.broadcast!(
      "room:#{room_id}",
      "user_left",
      %{
        user_id: user_id,
        state: %{
          participants: User.users_from_room(room_id)
        }
      }
    )
    {:noreply, socket}
  end

  # def terminate(_msg, %{assigns: %{user_id: user_id}, topic: "room:" <> room_id} = socket) do
  #   Endpoint.broadcast! socket.topic, "user_left", %{"user_id" => user_id}
  #   {:noreply, socket}
  # end

end
