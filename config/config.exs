# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :money_clip,
  ecto_repos: [MoneyClip.Repo]

# Configures the endpoint
config :money_clip, MoneyClipWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MGmQdv8pfS+lL0HQMkZxEpTl3LckgmWfXBz4UMYkT/lNucDBxwjU2x/2yBuKXcqw",
  render_errors: [view: MoneyClipWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MoneyClip.PubSub,
  live_view: [signing_salt: "0wk4FxXU"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
