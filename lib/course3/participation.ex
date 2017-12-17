defmodule Course3.Participation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.User
  alias Course3.Room

  schema "rooms_users" do
    belongs_to :user, User
    belongs_to :room, Room
    field :is_master, :boolean, default: false

    timestamps()
  end

end
