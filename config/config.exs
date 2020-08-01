# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :poker,
  ecto_repos: [Poker.Repo],
  delay_before_new_game_secs: 5

# Configures the endpoint
config :poker, PokerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Y/wOl9uAuzs73arBK28PDAp7kaSPSrh1O4cBa3dm8ue6NY3s6UIgXD9J42TKDdxI",
  render_errors: [view: PokerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Poker.PubSub,
  live_view: [signing_salt: "eV6tU1Ds"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
