defmodule Track do
  alias Course3.Like
  alias Course3.Repo

  def fetch_tracks(user_id, room_id, %{spotify_user_id: spotify_user_id, access_token: access_token} = _spotify_credentials) do
    %{body: %{"items" => items}} = SpotifyApi.get!("/v1/users/#{spotify_user_id}/playlists/#{room_id}/tracks", ["Authorization": "Bearer #{access_token}"])
    Enum.map items, fn(item) ->
      track = item["track"]
      {rating, liked} =
        Like
        |> Like.track_rating_and_if_liked_by(track["id"], room_id, user_id)
        |> Repo.one()
      track
      |> Map.take(~w(artists id name))
      |> Map.put("rating", rating)
      |> Map.put("liked", liked)
    end
  end

end
