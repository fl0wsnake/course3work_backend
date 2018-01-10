defmodule Course3.Knock do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.User
  alias Course3.Room

  @primary_key false
  schema "knocks" do
    belongs_to :user, User, primary_key: true
    belongs_to :room, Room, primary_key: true

    timestamps()
  end

  def changeset(knock, attrs) do
    knock
    |> cast(attrs, [:user_id, :room_id, :as_master])
    |> assoc_constraint(:room)
    |> assoc_constraint(:user)
  end

  # def for_room(query, room_id) do
  #   from k in query,
  #     where: room_id == ^room_id
  # end

  # def by_user_and_room(query, user_id, room_id) do
  #   from i in query,
  #     where: i.user_id == ^user_id,
  #     where: i.room_id == ^room_id
  # end

end
