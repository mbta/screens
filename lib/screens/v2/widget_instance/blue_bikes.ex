defmodule Screens.V2.WidgetInstance.BlueBikes do
  @moduledoc """
  A widget that displays real-time info about nearby BlueBikes stations.
  """
  alias Screens.BlueBikes
  alias Screens.BlueBikes.StationStatus
  alias Screens.Config.Screen
  alias Screens.Config.V2.PreFare

  @type t :: %__MODULE__{
          screen: Screen.t(),
          station_statuses: %{BlueBikes.station_id() => StationStatus.t()}
        }

  defstruct screen: nil, station_statuses: []

  def priority(%__MODULE__{screen: %Screen{app_params: %PreFare{}}} = t) do
    t.screen.app_params.blue_bikes.priority
  end

  def serialize(%__MODULE__{screen: %Screen{app_params: %PreFare{}}} = t) do
    widget_config = t.screen.app_params.blue_bikes

    station_statuses = t.station_statuses

    # get name and current status from station_status
    # get arrow and walk distance from config
    %{
      destination: widget_config.destination,
      minutes_range_to_destination: widget_config.minutes_range_to_destination,
      stations: Enum.map(widget_config.stations, &serialize_station(&1, station_statuses))
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

  def slot_names(_instance), do: [:lower_right]

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
