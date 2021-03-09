defmodule Screens.V2.WidgetInstance.NormalHeader do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalHeader

  defstruct screen: nil,
            station_name: nil,
            time: nil

  @type config :: :ok
  @type t :: %__MODULE__{
          screen: config(),
          station_name: String.t(),
          time: DateTime.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%NormalHeader{station_name: station_name, time: time}) do
      %{station_name: station_name, time: DateTime.to_iso8601(time)}
    end

    def slot_names(_instance), do: [:header]

    def widget_type(_instance), do: :normal_header
  end
end
