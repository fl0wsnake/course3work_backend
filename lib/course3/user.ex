defmodule Course3.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyToken

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    many_to_many :rooms_in, Room, join_through: "users_rooms"
    has_one :spotify_credentials, Course3.SpotifyCredentials
    has_many :owned_rooms, Room

    timestamps()
  end

  def token_changeset(user, attrs) do
    attrs = 
      attrs
      |> Map.put(:id, attrs.userid)
      |> Map.take(~w(id username email spotify_credentials))

    user
    # |> cast(attrs, ~w(userid username email spotify_credentials)a)

    # |> cast(attrs, ~w(userid username email))
    # |> put_assoc(:spotify_credentials, attrs["spotify_credentials"])

    |> cast(attrs, ~w(userid username email spotify_credentials))

    # |> change(%{id: attrs["userid"]})
    # |> cast(~w(id username email spotify_credentials)a)
  end

  def register_changeset(user, attrs) do
    required = ~w(username email password)a
    user
    |> cast(attrs, required)
    |> validate_required(required)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> change(Comeonin.Argon2.add_hash(attrs["password"]))
  end

  def login_changeset(user, attrs) do
    required = ~w(email password)a
    user
    |> cast(attrs, required)
    |> validate_required(required)
  end
end
