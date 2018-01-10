defmodule Course3Web.OptionsController do
  use Course3Web, :controller
  # import Plug.Conn

  def default(conn, _) do
    conn 
    # |> Plug.Conn.put_resp_header(
    #   "Access-Control-Allow-Origin",
    #   "*"
    # ) 
    |> put_resp_header(
      "Access-Control-Allow-Methods",
      "GET, POST, PATCH, PUT, DELETE, OPTIONS"
    )
    |> put_resp_header(
      "Access-Control-Allow-Headers",
      "Origin, X-Requested-With, X-Auth-Token, Content-Type, Accept"
    )
    |> json(%{})
  end

end
