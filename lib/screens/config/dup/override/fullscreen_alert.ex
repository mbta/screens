defmodule Screens.Config.Dup.Override.FullscreenAlert do
  @moduledoc false

  alias Screens.Config.V2.FreeTextLine

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

  use Screens.Config.Struct, children: [issue: FreeTextLine, remedy: FreeTextLine]

  def to_json(%__MODULE__{} = t) do
    t
    |> super()
    |> Map.put(:type, :fullscreen)
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

  defp value_to_json(_, value), do: value
end
