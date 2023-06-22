defmodule Screens.V2.DisruptionDiagram.Model do
  @moduledoc """
  Struct and functions to generate and model a disruption diagram.
  """

  # Model fields TBD
  defstruct []

  @type t :: %__MODULE__{}

  @type serialized_response :: %{
          l_end: end_slot(),
          r_end: end_slot(),
          middle_slots: list(middle_slot()),
          edges: list(edge())
        }

  @type end_slot :: destination() | terminal()

  @type middle_slot :: %{
          label: ellipsis() | %{full: String.t(), abbrev: String.t()},
          symbol: slot_symbol() | nil
        }

  # Literally the string "…", but you can't use string literals as types in elixir
  @type ellipsis :: String.t()

  @type destination :: %{
          destination_id: terminal_station() | aggregate_destination()
        }

  @type terminal :: %{
          station_id: terminal_station(),
          symbol: slot_symbol()
        }

  # Parent station ID of a terminal station
  @type terminal_station :: String.t()

  # two parent station IDs joined by "+", e.g. "place-asmnl+place-brntn" for Ashmont & Braintree
  @type aggregate_destination :: String.t()

  @type edge :: line_color() | disruption_edge()

  @type slot_symbol ::
          %{icon: :closed | :shuttled, color: disruption_color()}
          | %{icon: :open, color: line_color()}
          | :"you-are-here"
          | :"you-are-here--outline"

  @type line_color :: :blue | :orange | :red | :green

  @type disruption_edge :: :dashed | :thin

  @type disruption_color :: :black | :"you-are-here"

  @doc "Produces a JSON-serializable map representing the disruption diagram."
  # Update spec when this gets implemented!
  @spec serialize(t()) :: nil
  def serialize(_model) do
    nil
  end
end
