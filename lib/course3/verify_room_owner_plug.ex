defmodule Course3.Plugs.VerifyRoomOwner do
  import Plug.Conn
  alias Course3.User

  def init(options), do: options

  def call(conn, %{"room_id" => room_id}) do
    case User.is_owner?(conn.assigns.user_id, room_id) do
      nil ->
        conn
        |> put_status(401)
        |> send_resp()

      _ ->
        conn
    end
  end
end
