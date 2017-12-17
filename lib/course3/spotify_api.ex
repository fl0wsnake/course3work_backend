defmodule SpotifyApi do
  use HTTPoison.Base
  alias Course3.Like
  alias Course3.Repo

  # @expected_fields ~w(
  #   id
  # )

  def process_url(url), do: "https://api.spotify.com" <> url

  def process_headers(headers), do: ["Content-Type": "application/json"] ++ headers

  def process_response_body(body) do
    body
    |> Poison.decode!
    # |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def fetch_tracks(user_id, room_id) do
    %{"items" => items} = SpotifyApi.get!("/v1/users/#{user_id}/playlists/#{room_id}/tracks")
    Enum.map items, fn(item) -> 
      track = item["track"] 
      rating = 
        Like
        |> Like.for_track(track["id"], room_id)
        |> Like.track_rating()
        |> Repo.one!()
      track
      |> Map.take(~w(artists id images name)) 
      |> Map.put("rating", rating)
    end
  end

end
