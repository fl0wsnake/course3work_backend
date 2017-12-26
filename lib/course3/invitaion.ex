defmodule Course3.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.User
  alias Course3.Room

  schema "invitations" do
    belongs_to :user, User
    belongs_to :room, Room
    field :as_master, :boolean, default: false

    timestamps()
  end

  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:user_id, :room_id, :as_master])
    |> assoc_constraint(:room)
    |> assoc_constraint(:user)
  end

  def by_user_and_room(query, user_id, room_id) do
    from i in query,
      where: i.user_id == ^user_id,
      where: i.room_id == ^room_id
  end

  # def target_user(invitation) do
  #   invitation
  #   |> assoc(:user)
  #   |> Repo.one!()
  # end

end
