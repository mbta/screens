# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :screens, ScreensWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0XmZH5iePmWrvV+PgrsU5z6WFgYupY2Zoh7FEk8pzuDLWftBrF/KtLBbG615wstt",
  render_errors: [view: ScreensWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Screens.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :screens,
  screen_data: %{
    "1" => %{stop_id: "1722"},
    "2" => %{stop_id: "383"},
    "3" => %{stop_id: "5496"},
    "4" => %{stop_id: "2134"},
    "5" => %{stop_id: "32549"},
    "6" => %{stop_id: "22549"},
    "7" => %{stop_id: "5615"},
    "8" => %{stop_id: "36466"},
    "9" => %{stop_id: "11257"},
    "10" => %{stop_id: "58"},
    "11" => %{stop_id: "21365"},
    "12" => %{stop_id: "178"},
    "13" => %{stop_id: "6564"},
    "14" => %{stop_id: "1357"},
    "15" => %{stop_id: "390"},
    "16" => %{stop_id: "407"},
    "17" => %{stop_id: "5605"},
    "18" => %{stop_id: "637"},
    "19" => %{stop_id: "8178"},
    # detour
    "100" => %{stop_id: "2166"},
    # stop move
    "101" => %{stop_id: "150"},
    # stop closure
    "102" => %{stop_id: "1921"},
    # service change
    "103" => %{stop_id: "2085"},
    # station issue
    "104" => %{stop_id: "38671"}
  },
  api_v3_key: "ba359ac2ed5b41a5b05bfae67321766a",
  api_v3_url: "https://api-v3.mbta.com/"

  # api_v3_key: "b982dde8f59047da860575f09f7fae4b",
  # api_v3_url: "https://green.dev.api.mbtace.com/"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
