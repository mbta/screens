defmodule Screens.Config.V2.EvergreenContentItem do
  @moduledoc false

  alias Screens.Config.V2.Schedule
  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          slot_names: list(WidgetInstance.slot_id()),
          asset_path: String.t(),
          priority: WidgetInstance.priority(),
          schedule: list(Schedule.t()),
          text_for_audio: String.t(),
          audio_priority: WidgetInstance.priority()
        }

  @enforce_keys ~w[slot_names asset_path priority]a
  defstruct slot_names: nil,
            asset_path: nil,
            priority: nil,
            schedule: [%Schedule{}],
            text_for_audio: nil,
            audio_priority: nil

  use Screens.Config.Struct, children: [schedule: {:list, Schedule}]

  defp value_from_json("slot_names", slot_names) do
    Enum.map(slot_names, &String.to_existing_atom/1)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
