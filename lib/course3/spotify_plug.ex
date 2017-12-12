defmodule Course3.Plugs.FetchSubject do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    %{"sub" => subject} = Course3.Guardian.get_claims conn
    assign conn, :sub, subject
  end
end
