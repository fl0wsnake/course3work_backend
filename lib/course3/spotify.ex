defmodule SpotifyApi do
  use HTTPoison.Base

  @expected_fields ~w(
    id
  )

  def process_url(url) do
    "https://api.spotify.com" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
    # |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end