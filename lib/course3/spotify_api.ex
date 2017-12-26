defmodule SpotifyApi do
  use HTTPoison.Base
  alias Course3.Like
  alias Course3.Repo

  # @expected_fields ~w(
  #   id
  # )

  def process_url(url), do: "https://api.spotify.com" <> url

  defp process_request_headers(headers), 
    do: [
      "Content-Type": "application/json",
    ] ++ headers

  defp process_request_body(body), do: Poison.encode!(body)

  def process_response_body(body) do
    body
    |> Poison.decode!
    # |> Map.take(@expected_fields)
  end

  def fetch_tracks(user_id, room_id, %{access_token: access_token}) do
    %{body: %{"items" => items}} = SpotifyApi.get!("/v1/users/#{user_id}/playlists/#{room_id}/tracks", ["Authorization": "Bearer #{access_token}"])
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
