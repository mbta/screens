defmodule Screens.Config.V2.OvernightCRDepartures do
  @moduledoc false

  @type t :: %__MODULE__{
          overnight_weekday_text_english: String.t(),
          overnight_weekday_text_spanish: String.t(),
          overnight_weekend_text_english: String.t(),
          overnight_weekend_text_spanish: String.t()
        }

  defstruct overnight_weekday_text_english: nil,
            overnight_weekday_text_spanish: nil,
            overnight_weekend_text_english: nil,
            overnight_weekend_text_spanish: nil

  use Screens.Config.Struct, with_default: true

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
