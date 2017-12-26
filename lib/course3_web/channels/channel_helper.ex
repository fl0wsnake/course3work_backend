defmodule Course3Web.ChannelHelper do

  def get_room_id(socket) do
    "room:" <> room_id = socket.topic
    {room_id, _} = Integer.parse room_id
    room_id
  end

end
