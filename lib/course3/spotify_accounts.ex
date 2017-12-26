defmodule SpotifyAccounts do
  use HTTPoison.Base

  @expected_fields ~w(
    access_token refresh_token expires_in
  )

  def process_url(url), do: "https://accounts.spotify.com" <> url

  defp process_request_body(body), 
    do: body
    |> Enum.map(fn({k, v}) -> "#{k}=#{v}" end)
    |> Enum.join("&")

  def process_response_body(body) do
    body
    |> Poison.decode!
    |> Map.take(@expected_fields)
  end

  defp process_request_headers(headers) do
    client_id = Application.get_env(:course3, :spotify_client_id)
    client_secret = Application.get_env(:course3, :spotify_client_secret)
    auth_token = Base.encode64(client_id <> ":" <> client_secret)
    [
      "Authorization": "Basic #{auth_token}",
      "Content-Type": "application/x-www-form-urlencoded"
    ] ++ headers
  end

  # def auth_token() do
  #   client_id = Application.get_env(:course3, :spotify_client_id)
  #   client_secret = Application.get_env(:course3, :spotify_client_secret)
  #   auth_token = Base.encode64(client_id <> ":" <> client_secret)
  # end
end
