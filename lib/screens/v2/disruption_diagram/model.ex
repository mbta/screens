defmodule Screens.V2.DisruptionDiagram.Model do
  @moduledoc """
  Struct and functions to generate and model a disruption diagram.
  """

  # Model fields TBD
  defstruct []

  @type t :: %__MODULE__{}

  @type serialized_response :: %{
          l_end: end_node(),
          r_end: end_node(),
          middle_nodes: list(node()),
          edges: list(edge())
        }

  @type end_node :: destination() | terminal_node()

  @type node :: %{
          label: ellipsis() | %{full: String.t(), abbrev: String.t()},
          symbol: symbol() | nil
        }

  # Literally the string "…", but you can't use string literals as types in elixir
  @type ellipsis :: String.t()

  @type destination :: %{
          destination_id: terminal_station() | aggregate_destination()
        }

  @type terminal_node :: %{
          station_id: terminal_station(),
          symbol: symbol()
        }

  # Parent station ID of a terminal station
  @type terminal_station :: String.t()

  # two parent station IDs joined by "+", e.g. "place-asmnl+place-brntn" for Ashmont & Braintree
  @type aggregate_destination :: String.t()

  @type edge :: line_color() | disruption_edge()

  @type disruption_edge :: :dashed | :thin

  @type symbol ::
          %{icon: :closed | :shuttled, color: disruption_color()}
          | %{icon: :open, color: line_color()}
          | :"you-are-here"
          | :"you-are-here--outline"

  @type line_color :: :blue | :orange | :red | :green

  @type disruption_color :: :black | :"you-are-here"

  @doc "Produces a JSON-serializable map representing the disruption diagram."
  # Update spec when this gets implemented!
  @spec serialize(t()) :: nil
  def serialize(_model) do
    nil
  end
end
