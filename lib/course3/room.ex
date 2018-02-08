defmodule Course3.Room do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Room
  alias Course3.Repo
  alias Course3.User
  alias Course3.Knock

  @derive {Poison.Encoder, only: [:id, :name, :owner, :participants, :knocked_users]}
  @primary_key {:id, :string, []}
  schema "rooms" do
    field :name, :string
    belongs_to :owner, User
    many_to_many :participants, User, join_through: "users_rooms"
    many_to_many :knocked_users, User, join_through: "knocks"
    timestamps()
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:id, :name, :owner_id])
    |> validate_required([:id, :name, :owner_id])
  end

  # def show(room) do
  #   Map.take room, ~w(id name)a
  # end

  def participating_in(query, user_id) do
    from r in query,
      join: ur in "users_rooms",
      on: ur.user_id == ^user_id
  end

  # def with_owner(query) do
  #   from r in query,
  #     left_join: o in User,
  #     on: r.owner_id == o.id
  # end

  def with_owner(query) do
    from r in query,
      left_join: o in User,
      # preload: [owner: o]
      on: r.owner_id == o.id
  end

  def with_people_count(query) do
    from r in query,
      left_join: ur in "users_rooms",
      on: ur.room_id == r.id,
      group_by: r.id
  end

  # def if_knocked(query, user_id) do
  #   from r in query,
  #     left_join: k in Knock,
  #     on: r.id == k.room_id,
  #     where: k.user_id == ^user_id,
  #     group_by: k.user_id
  # end

  def get_rooms(user_id) do
    Room
    |> Room.with_owner()
    |> Room.with_people_count()
    |> group_by([r, o, ur], o.id)
    |> select(
      [r, o, ur], 
      {
        r.id, 
        r.name, 
        o.id,
        o.username, 
        count("ur.*"), 
        fragment("(select case when exists (select from knocks where room_id = ? and user_id = ?) then true else false end)", r.id, ^user_id),
        fragment("(select case when exists (select from users_rooms where room_id = ? and user_id = ? and is_master = true) then true else false end)", r.id, ^user_id)
      })
    |> Repo.all()
    |> Enum.map(fn tuple -> 
      {id, name, owner_id, owner_name, users_count, knocked, is_master} = tuple
      %{
        id: id,
        name: name,
        owner: %{
          id: owner_id,
          username: owner_name
        },
        users_count: users_count,
        knocked: knocked,
        is_master: is_master
      }
    end)
  end

  def get_rooms_in(user_id) do
    Room
    |> Room.participating_in(user_id)
    |> Room.with_owner()
    |> Room.with_people_count()
    |> group_by([r, _, o, ur], o.id)
    |> select(
      [r, _, o, ur], 
      {
        r.id,
        r.name,
        o.id,
        o.username,
        count("ur.*"),
        fragment("(select case when exists (select from users_rooms where room_id = ? and user_id = ? and is_master = true) then true else false end)", r.id, ^user_id)
      }
    )
    |> Repo.all()
    |> Enum.map(fn tuple -> 
      {id, name, owner_id, owner_name, users_count, is_master} = tuple
      %{
        id: id,
        name: name,
        owner: %{
          id: owner_id,
          username: owner_name
        },
        users_count: users_count,
        is_master: is_master
      }
    end)
  end

end

# defimpl Poison.Encoder, for: Room do
#   def encode(%{__struct__: _} = struct, options) do
#     map = struct
#           |> Map.from_struct
#           |> sanitize_map
#     Poison.Encoder.Map.encode(map, options)
#   end
#   defp sanitize_map(map) do
#     IO.inspect map
#     Map.take(map, [:id, :name])
#     |> IO.inspect()
#   end
# end

# defimpl Poison.Encoder, for: User do
#   def encode(%{__struct__: _} = struct, options) do
#     map = struct
#           |> Map.from_struct
#           |> sanitize_map
#     Poison.Encoder.Map.encode(map, options)
#   end
#   defp sanitize_map(map) do
#     Map.take(map, [:id, :username])
#   end
# end

# defimpl Poison.Encoder, for: Any do
#   def encode(%{__struct__: _} = struct, options) do
#     map = struct
#           |> Map.from_struct
#           |> sanitize_map
#     Poison.Encoder.Map.encode(map, options)
#   end
#   defp sanitize_map(map) do
#     Map.drop(map, [:__meta__, :__struct__])
#   end
# end

