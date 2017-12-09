defmodule Course3.Guardian do
  use Guardian, otp_app: :course3
  alias Course3.Repo
  alias Course3.User

  def subject_for_token(resource, _claims) do
    user = resource
           |> Map.take([:username, :email])
           |> Map.merge(%{userid: resource.id})

    spotify_credentials = if spotify_credentials = Map.get(
      resource,
      :spotify_credentials
    ) do
      Map.take(
        spotify_credentials,
        [
          :spotify_access_token,
          :spotify_expires_in,
          :spotify_refresh_token,
          :spotify_user_id
        ]
      )
    end

    user = user
           |> Map.put(:spotify_credentials, spotify_credentials)

    {:ok, user}
  end

  def resource_from_claims(claims) do
    IO.inspect claims
    {:ok, Repo.get!(User, claims["sub"]["userid"])}
  end

  def get_claims(conn) do
    Guardian.Plug.current_claims(conn, key: :impersonate)
  end

  def get_resource(conn) do
    Guardian.Plug.current_resource(conn, key: :impersonate)
  end
end
