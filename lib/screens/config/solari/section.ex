defmodule Screens.Config.Solari.Section do
  @moduledoc false

  alias Screens.Config.Query
  alias Screens.Config.Solari.Section.{Audio, Headway, Layout}
  alias Screens.Util

  @type t :: %__MODULE__{
          name: String.t(),
          arrow: :n | :e | :s | :w | :ne | :se | :sw | :nw | nil,
          query: Query.t(),
          layout: Layout.t(),
          audio: Audio.t(),
          pill: :bus | :red | :orange | :green | :blue | :cr | :mattapan | :silver,
          headway: Headway.t()
        }

  @enforce_keys [:name, :pill]
  defstruct name: nil,
            arrow: nil,
            query: Query.from_json(:default),
            layout: Layout.from_json(:default),
            audio: Audio.from_json(:default),
            pill: nil,
            headway: Headway.from_json(:default)

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

  for arrow <- ~w[n e s w ne se sw nw]a do
    arrow_string = Atom.to_string(arrow)

    defp value_from_json("arrow", unquote(arrow_string)) do
      unquote(arrow)
    end
  end

  defp value_from_json("query", query) do
    Query.from_json(query)
  end

  defp value_from_json("layout", layout) do
    Layout.from_json(layout)
  end

  defp value_from_json("audio", audio) do
    Audio.from_json(audio)
  end

  for pill <- ~w[bus red orange green blue cr mattapan silver]a do
    pill_string = Atom.to_string(pill)

    defp value_from_json("pill", unquote(pill_string)) do
      unquote(pill)
    end
  end

  defp value_from_json("headway", headway) do
    Headway.from_json(headway)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:query, query) do
    Query.to_json(query)
  end

  defp value_to_json(:layout, layout) do
    Layout.to_json(layout)
  end

  defp value_to_json(:audio, audio) do
    Audio.to_json(audio)
  end

  defp value_to_json(:headway, headway) do
    Headway.to_json(headway)
  end

  defp value_to_json(_, value), do: value
end
