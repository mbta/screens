defmodule Screens.Config.Dup do
  @moduledoc false

  alias Screens.Config.Dup.{Departures, Override}
  alias Screens.Util

  @type t :: %__MODULE__{
          primary: Departures.t(),
          secondary: Departures.t(),
          override: {Override.screen0(), Override.screen1()} | nil
        }

  defstruct primary: Departures.from_json(:default),
            secondary: Departures.from_json(:default),
            override: nil

  @spec from_json(map()) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_from_json("primary", primary) do
    Departures.from_json(primary)
  end

  defp value_from_json("secondary", secondary) do
    Departures.from_json(secondary)
  end

  defp value_from_json("override", [screen0, screen1]) do
    {Override.screen0_from_json(screen0), Override.screen1_from_json(screen1)}
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:primary, primary) do
    Departures.to_json(primary)
  end

  defp value_to_json(:secondary, secondary) do
    Departures.to_json(secondary)
  end

  defp value_to_json(:override, nil), do: nil

  defp value_to_json(:override, {screen0, screen1}) do
    [Override.screen0_to_json(screen0), Override.screen1_to_json(screen1)]
  end

  defp value_to_json(_, value), do: value
end
