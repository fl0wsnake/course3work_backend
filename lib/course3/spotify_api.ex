defmodule SpotifyApi do
  use HTTPoison.Base

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

  def authorization(%{access_token: access_token}) do
    ["Authorization": "Bearer #{access_token}"]
  end
end
