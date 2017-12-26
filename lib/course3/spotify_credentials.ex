defmodule Course3.SpotifyCredentials do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials

  schema "spotify_credentials" do
    field :access_token, :string
    field :expires_in, :integer
    field :refresh_token, :string
    field :spotify_user_id, :string
    belongs_to :user, User
    timestamps()
  end

  # def by_user_id_refreshed(user_id) do
  #   spotify_credentials = (
  #     from sc in SpotifyCredentials, 
  #     where: sc.user_id == ^user_id
  #   ) |> Repo.one()
  #   conn = assign conn, :sub, user_id
  #   assign conn, :spotify_credentials, spotify_credentials
  # end

  def owner_credentials_for_room(room_id) do
    spotify_credentials = (
      from sc in SpotifyCredentials,
      join: r in Room,
      where: sc.user_id == r.owner_id,
      where: r.id == ^room_id,
      select: "sc.*"
    ) |> Repo.one()
    if spotify_credentials, do: refresh spotify_credentials
  end

  def for_user(user_id) do
    spotify_credentials = (
      from sc in SpotifyCredentials,
      where: sc.user_id == ^user_id
    ) |> Repo.one()
    if spotify_credentials, do: refresh spotify_credentials
  end

  def refresh(credentials) do
    iat =
      credentials.inserted_at
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix()
    is_expired = :os.system_time(:second) - iat >= credentials.expires_in - 10
    if is_expired do
      %{body: %{"access_token" => access_token, "expires_in" => expires_in}} = SpotifyAccounts.post! "/api/token",
      %{
        "grant_type" => "refresh_token",
        "refresh_token" => credentials.refresh_token
      }
      credentials
      |> IO.inspect()
      |> change(%{
        access_token: access_token,
        expires_in: expires_in
      })
      |> Repo.update!()
    else
      credentials
    end
  end
end
