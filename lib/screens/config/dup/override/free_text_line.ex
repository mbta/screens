defmodule Screens.Config.Dup.Override.FreeTextLine do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeText

  @type t :: %__MODULE__{
          icon: icon,
          text: list(FreeText.t())
        }

  @type icon :: :warning | :x | :shuttle

  @enforce_keys ~w[icon text]a
  defstruct @enforce_keys

  for icon <- ~w[warning x shuttle]a do
    icon_string = Atom.to_string(icon)

    def from_json(%{"icon" => unquote(icon_string), "text" => free_text_elements}) do
      %__MODULE__{
        icon: unquote(icon),
        text: Enum.map(free_text_elements, &FreeText.from_json/1)
      }
    end
  end

  def to_json(%__MODULE__{icon: icon, text: free_text_elements}) do
    %{
      icon: icon,
      text: Enum.map(free_text_elements, &FreeText.to_json/1)
    }
  end
end
