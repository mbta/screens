defmodule Screens.Config.Dup.Override.FullscreenAlert do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Util

  @type t :: %__MODULE__{
          header: String.t() | nil,
          pattern: pattern,
          color: color,
          issue: FreeTextLine.t(),
          remedy: FreeTextLine.t()
        }

  @type pattern :: :hatched | :chevron | :x
  @type color :: :red | :orange | :green | :blue | :silver | :purple | :yellow

  @enforce_keys ~w[pattern color issue remedy]a
  defstruct [header: nil] ++ @enforce_keys

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
    |> Map.put(:type, :fullscreen)
  end

  defp value_from_json("issue", issue) do
    FreeTextLine.from_json(issue)
  end

  defp value_from_json("remedy", remedy) do
    FreeTextLine.from_json(remedy)
  end

  for pattern <- ~w[hatched chevron x]a do
    pattern_string = Atom.to_string(pattern)

    defp value_from_json("pattern", unquote(pattern_string)) do
      unquote(pattern)
    end
  end

  for color <- ~w[red orange green blue silver purple yellow]a do
    color_string = Atom.to_string(color)

    defp value_from_json("color", unquote(color_string)) do
      unquote(color)
    end
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:issue, issue) do
    FreeTextLine.to_json(issue)
  end

  defp value_to_json(:remedy, remedy) do
    FreeTextLine.to_json(remedy)
  end

  defp value_to_json(_, value), do: value
end
