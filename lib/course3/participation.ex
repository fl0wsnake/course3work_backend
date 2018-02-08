defmodule Course3.Participation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.User
  alias Course3.Room

  @primary_key false
  schema "users_rooms" do
    belongs_to :user, User, primary_key: true
    belongs_to :room, Room, type: :string, primary_key: true
    field :is_master, :boolean, default: false

    timestamps()
  end

  def changeset(knock, attrs) do
    knock
    |> cast(attrs, [:user_id, :room_id])
    |> assoc_constraint(:room)
    |> assoc_constraint(:user)
  end

end
