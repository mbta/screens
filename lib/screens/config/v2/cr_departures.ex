defmodule Screens.Config.V2.CRDepartures do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type platform_directions ::
          %{
            left: list(String.t()),
            right: list(String.t())
          }
          | String.t()

  @type t :: %__MODULE__{
          station: String.t(),
          destination: String.t(),
          direction_to_destination: 0 | 1,
          priority: WidgetInstance.priority(),
          travel_time_to_destination: String.t(),
          show_via_headsigns_message: true | false,
          wayfinding_arrows: platform_directions(),
          enabled: boolean()
        }

  defstruct station: nil,
            destination: nil,
            direction_to_destination: nil,
            priority: nil,
            travel_time_to_destination: nil,
            show_via_headsigns_message: nil,
            wayfinding_arrows: nil,
            enabled: false

  use Screens.Config.Struct, with_default: true

  defp value_from_json("wayfinding_arrows", wayfinding_arrows) when is_map(wayfinding_arrows) do
    Map.new(wayfinding_arrows, fn {direction, track_numbers} ->
      {direction, Enum.map(track_numbers, &to_string/1)}
    end)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
