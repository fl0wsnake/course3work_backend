defmodule Course3.Room do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Room
  alias Course3.User
  alias Course3.Invitation

  schema "rooms" do
    field :name, :string
    field :spotify_playlist_id, :string
    belongs_to :owner, User
    many_to_many :participants, User, join_through: "users_rooms"
    many_to_many :invited_users, User, join_through: "invitations"
    timestamps()
  end

  def changeset(%Room{} = room, attrs) do
    room
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name, :owner_id])
  end

  def participating_in(user_id) do
    from r in Room, 
      join: ur in Invitation,
      where: ur.user_id == ^user_id
  end

  def invited_in(user_id) do
    from r in Room, 
      join: ur in "users_rooms",
      where: ur.user_id == ^user_id
  end

  def with_owner(query) do
    from r in query,
      join: o in User,
      where: r.owner_id == o.id
  end

  def with_people_count(query) do
    from r in query,
      join: ur in "users_rooms",
      where: ur.room_id == r.id,
      group_by: r.id
  end

end
