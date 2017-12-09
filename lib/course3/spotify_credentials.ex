defmodule Course3.SpotifyCredentials do
  use Ecto.Schema
  import Ecto.Changeset
  alias Course3.User

  schema "spotify_credentials" do
    field :spotify_access_token, :string
    field :spotify_expires_in, :string
    field :spotify_refresh_token, :string
    field :spotify_user_id, :string
    belongs_to :user, User
    timestamps()
  end

  def changeset(spotify_credentials, attrs) do
    spotify_credentials
    |> cast(attrs, [:spotify_access_token, :spotify_expires_in, :spotify_refresh_token, :spotify_user_id])
  end
end
