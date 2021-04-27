defmodule Screens.Config.V2.BusShelter do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Departures, Footer, Header}
  alias Screens.Util

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: Header.t()
        }

  @enforce_keys [:departures, :footer, :header]
  defstruct departures: nil,
            footer: nil,
            header: nil

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

  defp value_from_json("departures", departures) do
    Departures.from_json(departures)
  end

  defp value_from_json("footer", footer) do
    Footer.from_json(footer)
  end

  defp value_from_json("header", header) do
    Header.from_json(header)
  end

  defp value_to_json(:departures, departures) do
    Departures.to_json(departures)
  end

  defp value_to_json(:footer, footer) do
    Footer.to_json(footer)
  end

  defp value_to_json(:header, header) do
    Header.to_json(header)
  end
end
