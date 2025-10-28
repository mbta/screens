defmodule Screens.Elevator do
  @moduledoc """
  Exposes hand-authored data about elevator accessibility that is not (yet?) available in GTFS.
  """

  alias Screens.Facilities.Facility
  alias Screens.Report

  @enforce_keys ~w[id alternate_ids exiting_summary redundancy summary]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: Facility.id(),
          alternate_ids: [Facility.id()],
          exiting_summary: String.t(),
          redundancy: :nearby | :in_station | :backtrack | :shuttle | :other,
          summary: String.t() | nil
        }

  @data_path :screens |> :code.priv_dir() |> Path.join("elevators.json")
  @data @data_path |> File.read!() |> Jason.decode!()
  @external_resource @data_path

  # Categories other than these will default to `:other`; we don't need to distinguish them.
  @redundancy_categories %{
    1 => :nearby,
    2 => :in_station,
    3 => :backtrack,
    4 => :shuttle
  }

  @callback get(Facility.id()) :: t() | nil
  def get(id) do
    case Map.get(@data, id) do
      nil ->
        Report.warning("elevator_redundancy_not_found", id: id)
        nil

      %{
        "alternate_ids" => alternate_ids,
        "category" => category,
        "exiting_summary" => exiting_summary,
        "summary" => summary
      } ->
        %__MODULE__{
          id: id,
          alternate_ids: alternate_ids,
          exiting_summary: exiting_summary,
          redundancy: Map.get(@redundancy_categories, category, :other),
          summary: summary
        }
    end
  end
end
