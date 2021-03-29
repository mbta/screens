defmodule Screens.Config.Dup.Override.PartialAlert do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeTextLine

  @type t :: %__MODULE__{
          color: color,
          content: FreeTextLine.t()
        }

  @type color :: :red | :orange | :green | :blue | :silver | :purple | :yellow

  @enforce_keys ~w[color content]a
  defstruct @enforce_keys

  for color <- ~w[red orange green blue silver purple yellow]a do
    color_string = Atom.to_string(color)

    def from_json(%{"color" => unquote(color_string), "content" => content}) do
      %__MODULE__{
        color: unquote(color),
        content: FreeTextLine.from_json(content)
      }
    end
  end

  def to_json(%__MODULE__{color: color, content: content}) do
    %{
      color: color,
      content: FreeTextLine.to_json(content)
    }
  end
end
