defmodule Screens.V2.WidgetInstance.BlueBikes do
  @moduledoc """
  A widget that displays real-time info about nearby BlueBikes stations.
  """
  alias Screens.BlueBikes
  alias Screens.BlueBikes.StationStatus
  alias Screens.Config.Screen
  alias Screens.Config.V2.BlueBikes.Station
  alias Screens.Config.V2.PreFare

  @type t :: %__MODULE__{
          screen: Screen.t(),
          station_statuses: %{BlueBikes.station_id() => StationStatus.t()}
        }

  @type widget_data :: %{
          destination: String.t(),
          minutes_range_to_destination: String.t(),
          stations: list(station_data)
        }

  @type station_data :: normal_station | special_station

  @type normal_station :: %{
          status: :normal,
          id: String.t(),
          arrow: Station.arrow(),
          walk_distance_minutes: non_neg_integer(),
          walk_distance_feet: non_neg_integer(),
          name: String.t(),
          num_bikes_available: non_neg_integer(),
          num_docks_available: non_neg_integer()
        }

  @type special_station :: %{
          status: :valet | :out_of_service,
          id: String.t(),
          arrow: Station.arrow(),
          walk_distance_minutes: non_neg_integer(),
          walk_distance_feet: non_neg_integer(),
          name: String.t()
        }

  defstruct screen: nil, station_statuses: []

  def priority(%__MODULE__{screen: %Screen{app_params: %PreFare{}}} = t) do
    t.screen.app_params.blue_bikes.priority
  end

  @spec serialize(t()) :: widget_data()
  def serialize(%__MODULE__{screen: %Screen{app_params: %PreFare{}}} = t) do
    widget_config = t.screen.app_params.blue_bikes

    station_statuses = t.station_statuses

    stations_data =
      widget_config.stations
      |> Enum.map(&serialize_station(&1, station_statuses))
      |> Enum.sort_by(& &1.walk_distance_minutes)
      |> Enum.take(2)

    # get name and current status from station_status
    # get arrow and walk distance from config
    %{
      destination: widget_config.destination,
      minutes_range_to_destination: widget_config.minutes_range_to_destination,
      stations: stations_data
    }
  end

  defp serialize_station(station, station_statuses) do
    status_data =
      case station_statuses[station.id] do
        %{status: {:normal, availability}} = status ->
          Map.merge(%{status: :normal, name: status.name}, availability)

        status ->
          Map.from_struct(status)
      end

    station
    |> Map.from_struct()
    |> Map.merge(status_data)
  end

  def slot_names(_instance), do: [:orange_line_surge_upper]

  def widget_type(_instance), do: :blue_bikes

  def valid_candidate?(_instance), do: true

  def audio_serialize(t), do: serialize(t)

  # Unsure for this one--it will partly depend on priority of other new widgets!
  def audio_sort_key(_instance), do: [2]

  def audio_valid_candidate?(_instance), do: true

  def audio_view(_instance), do: ScreensWeb.V2.Audio.BlueBikesView

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.BlueBikes

    def priority(instance), do: BlueBikes.priority(instance)
    def serialize(instance), do: BlueBikes.serialize(instance)
    def slot_names(instance), do: BlueBikes.slot_names(instance)
    def widget_type(instance), do: BlueBikes.widget_type(instance)
    def valid_candidate?(instance), do: BlueBikes.valid_candidate?(instance)

    def audio_serialize(instance), do: BlueBikes.audio_serialize(instance)
    def audio_sort_key(instance), do: BlueBikes.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: BlueBikes.audio_valid_candidate?(instance)
    def audio_view(instance), do: BlueBikes.audio_view(instance)
  end
end
