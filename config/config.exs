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
  api_v3_url: "https://api-v3.mbta.com/",
  nearby_connections: %{
    "1722" => ["place-matt", "place-DB-2222"],
    "383" => ["2923", "568"],
    "5496" => ["5403"],
    "2134" => ["place-FR-0074", "2137"],
    "32549" => ["place-harsq", "110"],
    "22549" => ["2168", "place-harsq"],
    "5615" => ["place-belsq", "place-ER-0046"],
    "36466" => ["26531", "place-NEC-2203"],
    "11257" => ["1144", "place-rcmnl"],
    "58" => ["1790", "5"],
    "21365" => ["place-rvrwy", "1314"],
    "178" => ["place-coecl", "175"],
    "6564" => ["place-sstat", "6538"],
    "1357" => ["place-rcmnl"],
    "390" => ["1332", "1569"],
    "407" => ["1346", "1583"],
    "5605" => ["place-belsq", "place-ER-0046"],
    "637" => ["6428", "place-NB-0064"],
    "8178" => ["900", "8297"]
  }

# api_v3_key: "b982dde8f59047da860575f09f7fae4b",
# api_v3_url: "https://green.dev.api.mbtace.com/"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
