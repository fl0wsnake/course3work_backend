defmodule Course3.Room do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Room
  alias Course3.Repo
  alias Course3.User
  alias Course3.SavedRoom

  @derive {Poison.Encoder, only: [:id, :name, :owner, :participants, :knocked_users]}
  @primary_key {:id, :string, []}
  schema "rooms" do
    field :name, :string
    belongs_to :owner, User
    many_to_many :participants, User, join_through: "users_rooms"
    many_to_many :knocked_users, User, join_through: "knocks"
    many_to_many :saved_rooms, User, join_through: "saved_rooms"
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

  def saved(query, user_id) do
    from r in query,
      join: s in SavedRoom,
      on: s.user_id == ^user_id
  end

  def with_owner(query) do
    from r in query,
      join: o in User,
      on: r.owner_id == o.id
  end

  def with_people_count(query) do
    from r in query,
      left_join: ur in "users_rooms",
      on: ur.room_id == r.id,
      group_by: r.id
  end

  def get_rooms() do
    Room
    |> Room.with_owner()
    |> Room.with_people_count()
    |> group_by([r, o, ur], o.id)
    |> select([r, o, ur], {r.id, r.name, o.username, count("ur.*")})
    |> Repo.all()
    |> Enum.map(fn tuple -> 
      {id, name, owner_name, users_count} = tuple
      %{
        id: id,
        name: name,
        owner_name: owner_name,
        users_count: users_count
      }
    end)
  end

  def get_rooms_in(user_id) do
      Room
      |> Room.participating_in(user_id)
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, _, o, ur], o.id)
      |> select([r, _, o, ur], {r.id, r.name, o.username, count("ur.*")})
      |> Repo.all()
      |> Enum.map(fn tuple -> 
        {id, name, owner_name, users_count} = tuple
        %{
          id: id,
          name: name,
          owner_name: owner_name,
          users_count: users_count
        }
      end)
  end

  def get_saved_rooms(user_id) do
      Room
      |> Room.saved(user_id)
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, i, o, ur], o.id)
      |> group_by([r, i, o, ur], i.room_id)
      |> group_by([r, i, o, ur], i.user_id)
      |> select([r, i, o, ur], {r.id, r.name, o.username, count("ur.*"), i.as_master})
      |> Repo.all()
      |> Enum.map(fn tuple -> 
        {id, name, owner_name, users_count, as_master} = tuple
        %{
          id: id,
          name: name,
          owner_name: owner_name,
          users_count: users_count,
          as_master: as_master
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

