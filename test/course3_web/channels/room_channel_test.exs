# defmodule Course3Web.RoomChannelTest do
#   use Course3Web.ChannelCase
#   alias Course3Web.RoomChannel

#   @user %{email: "test@test.test", username: "test", password: "qweqwe"}

#   setup do
#     conn = post conn, "/register", @user
#     %{"token" => token} = json_response conn, 200

#     {:ok, _, socket} =
#       socket("user_id", %{token: token})
#       |> subscribe_and_join(RoomChannel, "room:1")

#     {:ok, socket: socket}
#   end

#   test "ping replies with status ok", %{socket: socket} do
#     ref = push socket, "ping", %{"hello" => "there"}
#     assert_reply ref, :ok, %{"hello" => "there"}
#   end

#   test "shout broadcasts to room:lobby", %{socket: socket} do
#     push socket, "shout", %{"hello" => "all"}
#     assert_broadcast "shout", %{"hello" => "all"}
#   end

#   test "broadcasts are pushed to the client", %{socket: socket} do
#     broadcast_from! socket, "broadcast", %{"some" => "data"}
#     assert_push "broadcast", %{"some" => "data"}
#   end
# end
