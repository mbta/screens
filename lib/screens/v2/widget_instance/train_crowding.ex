defmodule Screens.V2.WidgetInstance.TrainCrowding do
  @moduledoc """
  A widget that displays the crowding on a train that is en route to the current station.
  """

  alias Screens.Config.Screen
  alias Screens.Config.V2.Triptych
  alias Screens.Predictions.Prediction

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
          now: String.t()
        }

  @type crowding_level :: :no_data | :not_crowded | :some_crowding | :crowded | :closed

  @spec serialize(t()) :: widget_data()
  def serialize(%__MODULE__{
        screen: %Screen{app_params: %Triptych{train_crowding: train_crowding}},
        prediction: prediction,
        now: now
      }) do
    %{
      destination: prediction.trip.headsign,
      crowding: serialize_carriages(prediction.vehicle.carriages),
      platform_position: train_crowding.platform_position,
      front_car_direction: train_crowding.front_car_direction,
      now: serialize_time(now)
    }
  end

  defp serialize_time(%DateTime{} = time) do
    DateTime.to_iso8601(time)
  end

  defp serialize_carriages(nil), do: nil

  defp serialize_carriages(carriages),
    do: Enum.map(carriages, fn car -> serialize_occupancy_status(car) end)

  defp serialize_occupancy_status(:no_data_available), do: :no_data
  defp serialize_occupancy_status(:many_seats_available), do: :not_crowded
  defp serialize_occupancy_status(:few_seats_available), do: :not_crowded
  defp serialize_occupancy_status(:standing_room_only), do: :some_crowding
  defp serialize_occupancy_status(:crushed_standing_room_only), do: :crowded
  defp serialize_occupancy_status(:full), do: :crowded
  defp serialize_occupancy_status(:not_accepting_passengers), do: :closed

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
