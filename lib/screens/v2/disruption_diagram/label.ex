defmodule Screens.V2.DisruptionDiagram.Label do
  @moduledoc """
  Functions for labeling disruption diagram slots.
  """

  alias Screens.Stops.Stop
  alias Screens.V2.DisruptionDiagram.Model

  @type branch :: :b | :c | :d | :e

  @doc "Returns the label for an omitted slot."
  @spec get_omission_label(MapSet.t(Stop.id()), Model.line_color(), branch() | nil) ::
          Model.label()
  def get_omission_label(omitted_stop_ids, :green, branch_thru_kenmore)
      when branch_thru_kenmore in [:b, :c, :d] do
    # For GL branches that pass through Kenmore, we look for Kenmore and Copley.
    [
      if("place-kencl" in omitted_stop_ids, do: "Kenmore"),
      if("place-coecl" in omitted_stop_ids, do: "Copley")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" & ")
    |> case do
      "" ->
        "…"

      stop_names ->
        text = "…via #{stop_names}"
        %{full: text, abbrev: text}
    end
  end

  def get_omission_label(omitted_stop_ids, :green, _trunk_or_e_branch) do
    # For E branch and trunk, we look for Government Center only.
    if "place-gover" in omitted_stop_ids,
      do: %{full: "…via Government Center", abbrev: "…via Gov't Ctr"},
      else: "…"
  end

  def get_omission_label(omitted_stop_ids, :red, _) do
    if "place-dwnxg" in omitted_stop_ids,
      do: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
      else: "…"
  end

  def get_omission_label(omitted_stop_ids, :orange, _) do
    if "place-dwnxg" in omitted_stop_ids,
      do: %{full: "…via Downtown Crossing", abbrev: "…via Downt'n Xng"},
      else: "…"
  end

  @doc "Returns the label ID for an end that contains more than one item."
  @spec get_end_label_id(Model.line_color(), Enumerable.t(Stop.id())) :: Model.end_label_id()
  def get_end_label_id(:orange, end_stop_ids) do
    label_id =
      cond do
        "place-forhl" in end_stop_ids -> "place-forhl"
        "place-ogmnl" in end_stop_ids -> "place-ogmnl"
      end

    label_id
  end

  def get_end_label_id(:red, end_stop_ids) do
    cond do
      "place-jfk" in end_stop_ids ->
        "place-asmnl+place-brntn"

      "place-alfcl" in end_stop_ids ->
        "place-alfcl"

      "place-asmnl" in end_stop_ids ->
        "place-asmnl"

      "place-brntn" in end_stop_ids ->
        "place-brntn"
    end
  end

  @doc """
  Returns the label ID for an end that contains more than one item, in a GL diagram.
  """
  @spec get_gl_end_label_id(branch() | nil, MapSet.t(Stop.id())) :: Model.end_label_id()
  def get_gl_end_label_id(nil, end_stop_ids) do
    # Trunk alert

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

  def get_gl_end_label_id(:b, end_stop_ids) do
    cond do
      "place-gover" in end_stop_ids -> "place-gover"
      "place-lake" in end_stop_ids -> "place-lake"
    end
  end

  def get_gl_end_label_id(:c, end_stop_ids) do
    cond do
      "place-gover" in end_stop_ids -> "place-gover"
      "place-clmnl" in end_stop_ids -> "place-clmnl"
    end
  end

  def get_gl_end_label_id(:d, end_stop_ids) do
    cond do
      "place-unsqu" in end_stop_ids -> "place-unsqu"
      "place-river" in end_stop_ids -> "place-river"
    end
  end

  def get_gl_end_label_id(:e, end_stop_ids) do
    cond do
      "place-mdftf" in end_stop_ids -> "place-mdftf"
      "place-hsmnl" in end_stop_ids -> "place-hsmnl"
    end
  end
end
