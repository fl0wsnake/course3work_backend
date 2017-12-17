defmodule Course3.SpotifyCredentials do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials

  schema "spotify_credentials" do
    field :spotify_access_token, :string
    field :spotify_expires_in, :string
    field :spotify_refresh_token, :string
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
      select: "sc.*"
    ) |> Repo.one!()

    refresh spotify_credentials
  end

  def refresh(credentials) do
    iat =
      credentials["inserted_at"]
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix()
    is_actual = :os.system_time(:second) - iat >= credentials["spotify_expires_in"] - 10
    credentials = if is_actual do
      new_credentials = SpotifyAccounts.post! "/api/token",
      %{
        "grant_type" => "refresh_token",
        "refresh_token" => credentials["refresh_token"]
      }
      Map.merge(credentials, new_credentials)
    else
      credentials
    end
    credentials
  end

  # def changeset(spotify_credentials, attrs) do
  #   spotify_credentials
  #   |> cast(attrs, [:spotify_access_token, :spotify_expires_in, :spotify_refresh_token, :spotify_user_id])
  # end

end
