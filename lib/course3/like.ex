defmodule Course3.Like do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Course3.Room
  alias Course3.User
  alias Course3.Like

  @primary_key false
  schema "likes" do
    field :track_id, :string, primary_key: true
    belongs_to :room, Room, type: :string, primary_key: true
    belongs_to :user, User, primary_key: true
    timestamps()
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:room_id, :track_id, :user_id])
    |> validate_required([:room_id, :track_id, :user_id])
  end

  def for_track(query, track_id, room_id) do
    from l in query,
      where: l.track_id == ^track_id,
      where: l.room_id == ^room_id
  end

  def track_rating(query) do
    from l in query,
      # group_by: l.room_id,
      # group_by: l.track_id,
      select: count(l.user_id)
  end

  # just for the sake of one query
  def track_rating_and_if_liked_by(query, track_id, room_id, user_id) do
    from l1 in for_track(query, track_id, room_id),
      select: {count(l1.user_id), fragment("(select case when exists (select from likes l2 where l2.track_id = ? and l2.room_id = ? and l2.user_id = ?) then true else false end)", ^track_id, ^room_id, ^user_id)}
  end

  def for_user(query, user_id) do
    from l in query,
      where: l.user_id == ^user_id
  end

end
