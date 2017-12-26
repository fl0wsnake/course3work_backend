defmodule Course3Web.ApiControllerTest do
  use Course3Web.ConnCase

  @user %{email: "test@test.test", username: "test", password: "qweqwe"}

  test "POST /register", %{conn: conn} do
    conn = post conn, "/register", @user
    json = json_response conn, 200
    assert json["token"]
  end

  test "POST /login", %{conn: conn} do
    conn = post conn, "/register", @user
    conn = post conn, "/login", Map.take(@user, [:email, :password])
    json = json_response conn, 200
    assert json["token"]
  end
end
