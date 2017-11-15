defmodule Course3Web.PageController do
  use Course3Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
