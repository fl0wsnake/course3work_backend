use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :course3, Course3Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :course3, Course3.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "pass1234",
  database: "db",
  hostname: "localhost",
  pool_size: 10

config :course3, Course3.Guardian,
       issuer: "course3_app",
       secret_key: "fZDwdWzrIyN/R5FvRUVvajUyrcTjc+HeUXwCPZlh95AqY6ftoP7hg9/sztzD3jqu"

config :argon2_elixir,
  t_cost: 1,
  m_cost: 8
