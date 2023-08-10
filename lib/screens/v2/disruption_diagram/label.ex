defmodule Screens.V2.DisruptionDiagram.Label do
  @moduledoc """
  Functions for labeling disruption diagram slots.
  """

  alias Screens.Stops.Stop
  alias Screens.V2.DisruptionDiagram, as: DD

  @doc "Returns the label for an omitted slot."
  @spec get_omission_label(MapSet.t(Stop.id()), DD.line(), DD.branch()) :: DD.label()
  def get_omission_label(omitted_stop_ids, :green, branch_thru_kenmore)
      when branch_thru_kenmore in [:b, :c, :d] do
    # For GL branches that pass through Kenmore, we look for Kenmore and Copley.
    [
      "place-kencl" in omitted_stop_ids and "Kenmore",
      "place-coecl" in omitted_stop_ids and "Copley"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" & ")
    |> case do
      "" -> "…"
      stop_names -> %{full: "…via #{stop_names}", abbrev: "…via #{stop_names}"}
    end
  end

  def get_omission_label(omitted_stop_ids, :green, _trunk_or_e_branch) do
    # For E branch and trunk, we look for Government Center only.
    if "place-gover" in omitted_stop_ids,
      do: %{full: "…via Government Center", abbrev: "…via Gov't Ctr"},
      else: "…"
  end

  # Orange and Red Lines both only look for Downtown Crossing.
  def get_omission_label(omitted_stop_ids, line, _) when line in [:orange, :red] do
    if "place-dwnxg" in omitted_stop_ids,
      do: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
      else: "…"
  end

  @doc "Returns the label ID for an end that contains more than one item."
  @spec get_end_label_id(MapSet.t(Stop.id()), DD.line(), DD.branch()) :: DD.end_label_id()
  def get_end_label_id(end_stop_ids, :orange, _) do
    cond do
      "place-forhl" in end_stop_ids -> "place-forhl"
      "place-ogmnl" in end_stop_ids -> "place-ogmnl"
    end
  end

  def get_end_label_id(end_stop_ids, :red, :trunk) do
    cond do
      "place-alfcl" in end_stop_ids -> "place-alfcl"
      "place-jfk" in end_stop_ids -> "place-asmnl+place-brntn"
    end
  end

  def get_end_label_id(end_stop_ids, :red, :ashmont) do
    cond do
      "place-alfcl" in end_stop_ids -> "place-alfcl"
      "place-asmnl" in end_stop_ids -> "place-asmnl"
    end
  end

  def get_end_label_id(end_stop_ids, :red, :braintree) do
    cond do
      "place-alfcl" in end_stop_ids -> "place-alfcl"
      "place-brntn" in end_stop_ids -> "place-brntn"
    end
  end

  def get_end_label_id(end_stop_ids, :green, :trunk) do
    cond do
      # left end
      "place-lech" in end_stop_ids -> "place-mdftf+place-unsqu"
      # right end
      # vvv
      "place-north" in end_stop_ids -> "place-north+place-pktrm"
      "place-gover" in end_stop_ids -> "place-gover"
      # ^^^ These two labels are not possible to produce.
      #     Diagrams for trunk alerts not extending past these stops are too small and will be padded to include them.
      "place-coecl" in end_stop_ids -> "place-coecl+west"
      "place-kencl" in end_stop_ids -> "place-kencl+west"
    end
  end

  def get_end_label_id(end_stop_ids, :green, :b) do
    cond do
      "place-gover" in end_stop_ids -> "place-gover"
      "place-lake" in end_stop_ids -> "place-lake"
    end
  end

  def get_end_label_id(end_stop_ids, :green, :c) do
    cond do
      "place-gover" in end_stop_ids -> "place-gover"
      "place-clmnl" in end_stop_ids -> "place-clmnl"
    end
  end

  def get_end_label_id(end_stop_ids, :green, :d) do
    cond do
      "place-unsqu" in end_stop_ids -> "place-unsqu"
      "place-river" in end_stop_ids -> "place-river"
    end
  end

  def get_end_label_id(end_stop_ids, :green, :e) do
    cond do
      "place-mdftf" in end_stop_ids -> "place-mdftf"
      "place-hsmnl" in end_stop_ids -> "place-hsmnl"
    end
  end
end
