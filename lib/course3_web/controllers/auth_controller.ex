defmodule Course3Web.AuthController do
  use Course3Web, :controller
  alias Course3.Repo
  alias Course3.User
  import Ecto.Query, only: [from: 2]

  # def allow_origin conn, _params do
  #   conn
  #   |> Plug.Conn.put_resp_header(
  #     "Access-Control-Allow-Origin",
  #     "*"
  #   )
  # end

  # def allow_cs conn, _params do 
  #   conn 
  #   |> Plug.Conn.put_resp_header(
  #     "Access-Control-Allow-Origin",
  #     "*"
  #   ) 
  #   |> Plug.Conn.put_resp_header(
  #     "Access-Control-Allow-Methods",
  #     "GET, POST, PATCH, PUT, DELETE, OPTIONS"
  #   )
  #   |> Plug.Conn.put_resp_header(
  #     "Access-Control-Allow-Headers",
  #     "Origin, X-Requested-With, X-Auth-Token, Content-Type, Accept, Authorization"
  #   )
  #   |> json(%{})
  # end

  def register(conn, _) do
    user = 
      %User{}
      |> User.register_changeset(conn.body_params)
      |> Repo.insert()

    case user do
      {:ok, user} ->
        {:ok, token, _} = Course3.Guardian.encode_and_sign(user)
        json conn, %{"token" => token}

      {:error, changeset} ->
        conn
          |> put_status(400)
          |> json(%{"error" =>
            changeset.errors
            |> Enum.map(fn {k, {v, _}} -> Atom.to_string(k) <> " " <> v end)})
    end
  end

  def login(conn, _) do
    %{"password" => password, "email" => email} = conn.body_params
    user = Repo.one(from u in User, where: u.email == ^email, preload: :spotify_credentials)
    cond do
      user && Comeonin.Argon2.checkpw(password, user.password_hash) ->
        {:ok, token, _} = Course3.Guardian.encode_and_sign(user)
        json conn, %{"token" => token}

      user ->
        conn
          |> put_status(401)
          |> json(%{"error" => "Wrong password"})

      true ->
        conn
          |> put_status(401)
          |> json(%{"error" => "Wrong email"})
    end
  end
end
