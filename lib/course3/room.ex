defmodule Course3.Room do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Room
  alias Course3.User

  schema "rooms" do
    field :name, :string
    field :owner_id, :id
    many_to_many :users, User, join_through: "users_rooms"

    timestamps()
  end

  def changeset(%Room{} = room, attrs) do
    room
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name, :owner_id])
  end

  def for_user_id(user_id) do
    # query
    # |> join(:inner, [u], ur in "users_rooms", u.id == ur.user_id)
    # |> join(:inner, [u, ur], r in Room, ur.room_id == r.id)
    from r in Room, 
      join: ur in "users_rooms",
      where: ur.user_id == ^user_id
  end

  def with_owner(query) do
    # query
    # |> join(:inner, [o], User, o.id == r.owner_id)
    from r in query,
      join: o in User,
      where: r.owner_id == o.id
  end

  def with_people_count(query) do
    # query
    # |> join(:inner, [urs], "users_rooms", urs.room_id == r.id)
    # |> join(:inner, [us], Room, us.id == urs.user_id)
    # |> group_by([])
    from r in query,
      join: ur in "users_rooms",
      where: ur.room_id == r.id,
      group_by: r.id
  end

end
