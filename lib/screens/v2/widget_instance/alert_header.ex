defmodule Screens.V2.WidgetInstance.AlertHeader do
  @moduledoc false

  alias Screens.V2.WidgetInstance.AlertHeader

  defstruct screen: nil,
            text: nil,
            icon: nil,
            color: nil,
            accent: nil,
            time: nil

  @type icon :: :logo | :green_b | :green_c | :green_d | :green_e
  @type color :: :blue | :green | :orange | :purple | :red | :yellow | :silver
  @type accent :: :x | :hatched | :chevron

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          text: String.t(),
          icon: icon,
          color: color,
          accent: accent,
          time: DateTime.t() | nil
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%AlertHeader{text: text, icon: icon, color: color, accent: accent, time: time}) do
      %{text: text, icon: icon, color: color, accent: accent, time: serialize_time(time)}
    end

    defp serialize_time(%DateTime{} = time) do
      DateTime.to_iso8601(time)
    end

    defp serialize_time(nil), do: nil

    def slot_names(_instance), do: [:header]

    def widget_type(_instance), do: :alert_header

    def valid_candidate?(_instance), do: true
  end
end
