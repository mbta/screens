defmodule Screens.V2.WidgetInstance.TrainCrowding do
  @moduledoc """
  A widget that displays the crowding on a train that is en route to the current station.
  """

  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Triptych
  alias Screens.Predictions.Prediction
  alias Screens.Util

  defstruct screen: nil,
            prediction: nil,
            now: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          prediction: Prediction.t(),
          now: DateTime.t()
        }

  @type widget_data :: %{
          destination: String.t(),
          crowding: list(crowding_level),
          # Describes where the "you are here" arrow should be positioned.
          # 1: leftmost, 25: rightmost
          platform_position: 1..25,
          front_car_direction: :left | :right,
          now: String.t(),
          show_identifiers: boolean()
        }

  @type crowding_level :: :no_data | :not_crowded | :some_crowding | :crowded | :closed

  @spec serialize(t()) :: widget_data()
  def serialize(%__MODULE__{
        screen: %Screen{
          app_params: %Triptych{
            train_crowding: train_crowding,
            show_identifiers: show_identifiers
          }
        },
        prediction: prediction,
        now: now
      }) do
    %{
      destination: prediction.trip.headsign,
      crowding: serialize_carriages(prediction.vehicle.carriages),
      platform_position: train_crowding.platform_position,
      front_car_direction: train_crowding.front_car_direction,
      now: serialize_time(now),
      show_identifiers: show_identifiers
    }
  end

  defp serialize_time(%DateTime{} = time) do
    DateTime.to_iso8601(time)
  end

  defp serialize_carriages(nil), do: nil

  defp serialize_carriages(carriages),
    do: Enum.map(carriages, &Util.translate_carriage_occupancy_status(&1.occupancy_status))

  def priority(_instance), do: [1]

  def slot_names(_instance), do: [:full_screen]

  def widget_type(_instance), do: :train_crowding

  def valid_candidate?(_instance), do: true

  ### Required audio callbacks. The widget does not have audio equivalence, so these are "stubbed".
  def audio_serialize(_t), do: %{}
  def audio_sort_key(_t), do: [0]
  def audio_valid_candidate?(_t), do: false
  def audio_view(_t), do: nil

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.TrainCrowding

    def priority(instance), do: TrainCrowding.priority(instance)
    def serialize(instance), do: TrainCrowding.serialize(instance)
    def slot_names(instance), do: TrainCrowding.slot_names(instance)
    def widget_type(instance), do: TrainCrowding.widget_type(instance)
    def valid_candidate?(instance), do: TrainCrowding.valid_candidate?(instance)

    def audio_serialize(instance), do: TrainCrowding.audio_serialize(instance)
    def audio_sort_key(instance), do: TrainCrowding.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: TrainCrowding.audio_valid_candidate?(instance)
    def audio_view(instance), do: TrainCrowding.audio_view(instance)
  end
end
