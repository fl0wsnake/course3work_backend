# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :course3,
  ecto_repos: [Course3.Repo]

# Configures the endpoint
config :course3, Course3Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "t/VxerNN1g9EEQDoAMH1hxM3dyaiL9jgVGN0NSaeDECvCC9i5UKT2JIhSB4YndxZ",
  render_errors: [view: Course3Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Course3.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
