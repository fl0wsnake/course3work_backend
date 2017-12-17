defmodule Course3.Like do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Room
  alias Course3.User
  alias Course3.Like

  # @primary_key {:id, :string, []}
  schema "likes" do
    belongs_to :rooms, Room
    field :track_id, :string
    belongs_to :users, User
    timestamps()
  end

  def track_rating(query) do
    from l in query,
      group_by: l.room_id,
      group_by: l.track_id,
      select: count("l.*")
  end

  def for_track(query, track_id, room_id) do
    from l in query,
      where: l.room_id == ^room_id,
      where: l.track_id == ^track_id
  end

  def for_user(query, user_id) do
    from l in query,
      where: l.user_id == ^user_id
  end

end
