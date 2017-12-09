defmodule Course3Web.AuthController do
  use Course3Web, :controller
  alias Course3.Repo
  alias Course3.User
  alias Course3.SpotifyCredentials
  import Ecto.Query, only: [from: 2]

  def register(conn, _) do
    user = User.register_changeset(%User{}, conn.body_params)
    user = Repo.insert(user)

    case user do
      {:ok, user} ->
        {:ok, token, _} = Course3.Guardian.encode_and_sign(user)
        json conn, %{"token" => token}

      {:error, changeset} ->
        conn
          |> put_status(400)
          |> json(%{"error_message" =>
            changeset.errors
            |> Enum.map(fn {k, {v, _}} -> Atom.to_string(k) <> " " <> v end)})
    end
  end

  def login(conn, _) do
    %{"password" => password, "email" => email} = conn.body_params
    [user] = Repo.all(from u in User, where: u.email == ^email, preload: :spotify_credentials)
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
