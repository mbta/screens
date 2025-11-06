defmodule Screens.V2.WidgetInstance.SubwayStatus do
  @moduledoc """
  A flex-zone widget that displays a brief status of each subway line.
  """

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.SubwayStatus
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils
  alias ScreensConfig.Screen

  defmodule SubwayStatusAlert do
    @moduledoc false

    @type t :: %__MODULE__{
            alert: Alert.t(),
            context: context()
          }

    @enforce_keys [:alert]
    defstruct @enforce_keys ++ [context: %{}]

    @type context :: %{
            optional(:all_platforms_at_informed_stations) => list(String.t())
          }
  end

  defstruct screen: nil,
            subway_alerts: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          subway_alerts: list(SubwayStatusAlert.t())
        }

  @type alerts_by_route :: %{Route.id() => list(SubwayStatusAlert.t())}

  @type serialized_response :: %{
          blue: section(),
          orange: section(),
          red: section(),
          green: section()
        }

  @type section :: extended_section() | contracted_section()

  @type extended_section :: %{
          type: :extended,
          alert: alert()
        }

  @type contracted_section :: %{type: :contracted, alerts: list(alert())}

  @type alert :: %{
          optional(:route_pill) => route_pill(),
          optional(:station_count) => integer(),
          status: String.t(),
          location: String.t() | location_map() | nil
        }

  @type location_map :: %{full: String.t(), abbrev: String.t()}

  @type route_pill :: %{
          optional(:branches) => list(branch()),
          type: :text,
          text: String.t(),
          color: route_color()
        }

  @type branch :: :b | :c | :d | :e | :m

  @type route_color :: :red | :orange | :green | :blue

  defimpl Screens.V2.WidgetInstance do
    alias ScreensConfig.Audio
    alias ScreensConfig.Screen.BusShelter

    def priority(_instance), do: [2, 1]

    @spec serialize(SubwayStatus.t()) :: SubwayStatus.serialized_response()
    def serialize(%SubwayStatus{subway_alerts: alerts}) do
      # Serializes by following the below process:
      # 1. Fetch potential relevant alerts for each line
      # 2. Serialize with maximum number of rows for each section
      # 3. Consolidate sections if there are too many with 2 alert rows
      # 4. Marks alert rows as extended if there is space
      alerts
      |> SubwayStatus.get_relevant_alerts_by_route()
      |> Serialize.serialize_alerts_into_possible_rows()
      |> Serialize.consolidate_alert_sections()
      |> Serialize.extend_sections_if_needed()
    end

    def slot_names(_instance), do: [:medium, :large]

    def widget_type(_instance), do: :subway_status

    def valid_candidate?(_instance), do: true

    def audio_serialize(t), do: serialize(t)

    def audio_sort_key(_instance), do: [3]

    def audio_valid_candidate?(%SubwayStatus{
          screen: %Screen{app_params: %BusShelter{audio: %Audio{interval_enabled: true}}}
        }),
        do: false

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.SubwayStatusView
  end

  # Filters alerts by route and returns a map of route IDs to lists of alerts
  @spec get_relevant_alerts_by_route(list(SubwayStatusAlert.t())) :: alerts_by_route()
  def get_relevant_alerts_by_route(alerts) do
    alerts
    |> Stream.flat_map(fn alert ->
      alert
      |> Utils.alert_routes()
      |> Enum.uniq()
      |> Enum.map(fn route -> {alert, route} end)
    end)
    |> Enum.group_by(
      fn {_alert, route} -> route end,
      fn {alert, _route} -> alert end
    )
  end
end
