defmodule Screens.Lines.Line do
  @moduledoc false

  defstruct ~w[id long_name short_name sort_order]a

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id(),
          long_name: String.t(),
          short_name: String.t(),
          sort_order: integer()
        }

  @spec cr_line?(t()) :: boolean()
  def cr_line?(%__MODULE__{id: "line-CR-" <> _line}), do: true
  def cr_line?(_), do: false

  @spec subway_or_light_rail_line?(t()) :: boolean()
  def subway_or_light_rail_line?(%__MODULE__{id: "line-Blue"}), do: true
  def subway_or_light_rail_line?(%__MODULE__{id: "line-Orange"}), do: true
  def subway_or_light_rail_line?(%__MODULE__{id: "line-Red"}), do: true
  def subway_or_light_rail_line?(%__MODULE__{id: "line-Green"}), do: true
  def subway_or_light_rail_line?(%__MODULE__{id: "line-Mattapan"}), do: true
  def subway_or_light_rail_line?(_), do: false
end
