defmodule Screens.Config.Dup.Override.PartialAlert do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeTextLine

  @type t :: %__MODULE__{
          affected: pill,
          content: FreeTextLine.t()
        }

  @type pill :: :red | :orange | :green | :blue | :mattapan | :cr

  @enforce_keys ~w[affected content]a
  defstruct @enforce_keys

  for pill <- ~w[red orange green blue mattapan cr]a do
    pill_string = Atom.to_string(pill)

    def from_json(%{"affected" => unquote(pill_string), "content" => content}) do
      %__MODULE__{
        affected: unquote(pill),
        content: FreeTextLine.from_json(content)
      }
    end
  end

  def to_json(%__MODULE__{affected: affected, content: content}) do
    %{
      affected: affected,
      content: FreeTextLine.to_json(content)
    }
  end
end
