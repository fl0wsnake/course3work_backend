defmodule Course3Web.UserSocket do
  use Phoenix.Socket

  channel "room:*", Course3Web.RoomChannel
  channel "user:*", Course3Web.InvitationChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(%{"token" => token}, socket) do
    case Course3.Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        socket = assign(socket, :user_id, claims["sub"])
        {:ok, socket}

      {:error, reason} ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  # def id(socket), do: "user_socket:#{socket.sub}"
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
