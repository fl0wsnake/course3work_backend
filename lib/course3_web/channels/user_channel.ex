defmodule Course3Web.UserChannel do
  use Course3Web, :channel

  def join("user:" <> user_id, payload, socket) do
    rooms_in =
      conn.assigns.user_id
      |> Room.participating_in()
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, _, o, ur], o.id)
      |> select([r, _, o, ur], {r.name, o.username, count("ur.*")})
      |> Repo.all()
    rooms_invited_in =
      conn.assigns.user_id
      |> Room.invited_in()
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, _, o, ur], o.id)
      |> select([r, _, o, ur], {r.name, o.username, count("ur.*")})
      |> Repo.all()
    rooms =
      Room
      |> Room.with_owner()
      |> Room.with_people_count()
      |> group_by([r, o, ur], o.id)
      |> select([r, o, ur], {r.name, o.username, count("ur.*")})
      |> Repo.all()
    broadcast(
      "user:#{socket.assigns.user_id}",
      "directory",
      %{
        "rooms" => rooms,
        "rooms_in" => rooms_in,
        "rooms_invited_in" => rooms_invited_in,
        "client_id" => Application.get_env(:course3, :spotify_client_id)
      }
    )
    {:ok, socket}
  end

  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  # def handle_in("shout", payload, socket) do
  #   broadcast socket, "shout", payload
  #   {:noreply, socket}
  # end

end
