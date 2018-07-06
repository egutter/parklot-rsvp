# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :parklot_rsvp,
  ecto_repos: [ParklotRsvp.Repo]

# Configures the endpoint
config :parklot_rsvp, ParklotRsvpWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SXDbSNWaCLMMY3NIB1NRK8DZtIzSYYP1YBDpOsEYSywpJzzl2/i8eP8dhWberRnG",
  render_errors: [view: ParklotRsvpWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: ParklotRsvp.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"