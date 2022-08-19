defmodule Screens.Config.Dup do
  @moduledoc false

  alias Screens.Config.Dup.{Departures, Override}

  @type t :: %__MODULE__{
          primary: Departures.t(),
          secondary: Departures.t(),
          override: {Override.screen0(), Override.screen1(), Override.screen2()} | nil
        }

  defstruct primary: Departures.from_json(:default),
            secondary: Departures.from_json(:default),
            override: nil

  use Screens.Config.Struct, children: [primary: Departures, secondary: Departures]

  defp value_from_json("override", [screen0, screen1, screen2]) do
    {Override.screen0_from_json(screen0), Override.screen1_from_json(screen1),
     Override.screen2_from_json(screen2)}
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:override, {screen0, screen1, screen2}) do
    [
      Override.screen0_to_json(screen0),
      Override.screen1_to_json(screen1),
      Override.screen2_to_json(screen2)
    ]
  end

  defp value_to_json(_, value), do: value
end
