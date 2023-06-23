defmodule Screens.V2.DisruptionDiagram.AlternateModel do
  @moduledoc """
  Alternate structure for serialization of the disruption diagram model.
  """

  # Model fields TBD
  defstruct []

  @type t :: %__MODULE__{}

  @type serialized_response :: continuous_disruption_diagram() | discrete_disruption_diagram()

  @type continuous_disruption_diagram :: %{
          effect: :shuttle | :suspension,
          # A 2-element list, giving indices of the effect region's *first and last disrupted stops*.
          # For example in this scenario:
          #     0     1     2     3     4     5     6
          #    <= === O - - X - - X - - X - - O === =>
          #                 |---range---|
          # The range is [2, 4].
          effect_region_slot_index_range: list(non_neg_integer()),
          line: line_color(),
          current_station_slot_index: non_neg_integer() | nil,
          # First and last elements of the list are `end_slot`s, middle elements are `middle_slot`s.
          slots: list(slot())
        }

  @type discrete_disruption_diagram :: %{
          effect: :station_closure,
          closed_station_slot_indices: list(non_neg_integer()),
          line: line_color(),
          current_station_slot_index: non_neg_integer() | nil,
          # First and last elements of the list are `end_slot`s, middle elements are `middle_slot`s.
          slots: list(slot())
        }

  @type slot :: end_slot() | middle_slot()

  @type end_slot :: %{
          type: :arrow | :terminal,
          label_id: end_label_id()
        }

  @type middle_slot :: %{
          label: label(),
          show_symbol: boolean()
        }

  @type label :: ellipsis() | %{full: String.t(), abbrev: String.t()}

  # Literally the string "…", but you can't use string literals as types in elixir
  @type ellipsis :: String.t()

  # End labels have hardcoded presentation, so we just send an ID for the client to use in
  # a lookup.
  #
  # TBD what these IDs will look like. We might just use parent station IDs.
  #
  # The rest of the labels' presentations are computed based on the height of the end labels,
  # so we can send actual text for those--it will be dynamically resized to fit.
  @type end_label_id :: String.t()

  @type line_color :: :blue | :orange | :red | :green

  @doc "Produces a JSON-serializable map representing the disruption diagram."
  # Update spec when this gets implemented!
  @spec serialize(t()) :: nil
  def serialize(_model) do
    nil
  end
end
