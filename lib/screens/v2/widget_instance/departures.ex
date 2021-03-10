defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc false

  alias Screens.Predictions.Prediction

  @type config :: :ok

  defstruct screen: nil,
            predictions: []

  @type t :: %__MODULE__{
          screen: config(),
          predictions: list(Prediction.t())
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(instance) do
      departures =
        instance.predictions
        |> Enum.sort_by(& &1.departure_time)
        |> Enum.map(&serialize_prediction/1)

      %{departures: departures}
    end

    defp serialize_prediction(%Prediction{
           route: route,
           trip: trip,
           departure_time: departure_time
         }) do
      %{route: route.short_name, destination: trip.headsign, time: departure_time}
    end

    def slot_names(_instance), do: [:main_content]

    def widget_type(_instance), do: :departures
  end
end
