defmodule Course3.Knock do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.User
  alias Course3.Room
  alias Course3.Knock
  alias Course3.Repo

  @primary_key false
  schema "knocks" do
    belongs_to :user, User, primary_key: true
    belongs_to :room, Room, type: :string, primary_key: true
    timestamps()
  end

  def changeset(knock, attrs) do
    knock
    |> cast(attrs, [:user_id, :room_id])
    |> assoc_constraint(:room)
    |> assoc_constraint(:user)
  end

  def has_knocked(user_id, room_id) do
    (
      from k in Knock,
      where: k.user_id == ^user_id,
      where: k.room_id == ^room_id
    ) |> Repo.one()
  end

  def by_user_and_room(query, user_id, room_id) do
    from k in query,
      where: k.user_id == ^user_id,
      where: k.room_id == ^room_id
  end

  def by_room(query, room_id) do
    from k in query,
      where: k.room_id == ^room_id
  end

end
