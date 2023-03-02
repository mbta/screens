defmodule Screens.Config.Dup.Override.PartialAlert do
  @moduledoc false

  alias Screens.Config.V2.FreeTextLine

  @type t :: %__MODULE__{
          color: color,
          content: FreeTextLine.t()
        }

  @type color :: :red | :orange | :green | :blue | :silver | :purple | :yellow

  @enforce_keys ~w[color content]a
  defstruct @enforce_keys

  use Screens.Config.Struct, children: [content: FreeTextLine]

  for color <- ~w[red orange green blue silver purple yellow]a do
    color_string = Atom.to_string(color)

    defp value_from_json("color", unquote(color_string)) do
      unquote(color)
    end
  end

  defp value_to_json(_, value), do: value
end
