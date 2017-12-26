defmodule Course3.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Repo
  alias Course3.User
  alias Course3.Room
  alias Course3.SpotifyCredentials
  alias Course3.Like

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    many_to_many :rooms_in, Room, join_through: "users_rooms"
    many_to_many :invited_in, Room, join_through: "invitations"
    has_one :spotify_credentials, SpotifyCredentials
    has_many :owned_rooms, Room, foreign_key: :owner_id
    has_many :likes, Like

    timestamps()
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

  def from_room(query, room_id) do
    from u in query,
      join: ur in "user_rooms",
      where: ur.room_id == ^room_id
  end

  def invited_in_room(query, room_id) do
    from u in query,
      join: i in "invited",
      where: i.room_id == ^room_id
  end

  def in_room?(user_id, room_id) do
    (
      from ur in "users_rooms",
      where: ur.room_id == ^room_id,
      where: ur.user_id == ^user_id
    ) |> Repo.one!()
  end

  def is_master?(user_id, room_id) do
    (
      from ur in "users_rooms",
      where: ur.room_id == ^room_id,
      where: ur.user_id == ^user_id,
      where: ur.is_master == true
    ) |> Repo.one!()
  end

  def is_owner?(user_id, room_id) do
    (
      from r in Room,
      where: r.id == ^room_id,
      where: r.owner_id == ^user_id
    ) |> Repo.one!()
  end

  def show(user) do
    Map.take user, ~w(username, id)a
  end
end
