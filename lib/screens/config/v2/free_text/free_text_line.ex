defmodule Screens.Config.V2.FreeTextLine do
  @moduledoc false

  alias Screens.Config.V2.FreeText

  @type t :: %__MODULE__{
          icon: icon,
          text: list(FreeText.t())
        }

  @type icon ::
          :warning
          | :x
          | :shuttle
          | :subway
          | :cr
          | :walk
          | :red
          | :blue
          | :orange
          | :green
          | :silver
          | :green_b
          | :green_c
          | :green_d
          | :green_e
          | nil

  @enforce_keys ~w[icon text]a
  defstruct @enforce_keys

  use Screens.Config.Struct, children: [text: {:list, FreeText}]

  def to_plaintext(%__MODULE__{text: text}) do
    text
    |> Enum.map(&FreeText.to_plaintext/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  for icon <-
        ~w[warning x shuttle subway cr walk red blue orange green silver green_b green_c green_d green_e]a do
    icon_string = Atom.to_string(icon)

    defp value_from_json("icon", unquote(icon_string)) do
      unquote(icon)
    end
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
