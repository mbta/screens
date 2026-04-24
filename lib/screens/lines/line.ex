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

  def color("line-Red"), do: :red
  def color("line-Mattapan"), do: :red
  def color("line-Orange"), do: :orange
  def color("line-Green" <> _), do: :green
  def color("line-Blue"), do: :blue
  def color("line-CR-" <> _), do: :purple
  def color(_), do: :yellow
end
