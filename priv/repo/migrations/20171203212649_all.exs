defmodule Course3.Repo.Migrations.All do
  use Ecto.Migration

  def change do

    create table(:users) do
      add :username, :string
      add :email, :string
      add :password_hash, :string
      add :is_premium, :boolean, default: false
      add :is_admin, :boolean, default: false
      timestamps()
    end
    create unique_index(:users, [:email])

    create table(:rooms, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string
      add :password_hash, :string
      add :owner_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end
    create index(:rooms, [:owner_id])

    create table(:users_rooms, primary_key: false) do
      add :room_id, references(:rooms, on_delete: :delete_all, type: :string), primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :is_master, :boolean, default: false
    end

    create table(:spotify_credentials) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :spotify_user_id, :string
      add :spotify_refresh_token, :string
      add :spotify_access_token, :string
      add :spotify_expires_in, :string
      timestamps()
    end

    create table(:likes, primary_key: false) do
      add :room_id, references(:rooms, on_delete: :delete_all, type: :string), primary_key: true
      add :track_id, :string, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
    end

    create table(:invitations, primary_key: false) do
      add :room_id, references(:rooms, on_delete: :delete_all, type: :string), primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :as_master, :boolean, default: false
      timestamps()
    end

  end
end
