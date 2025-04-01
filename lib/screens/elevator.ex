defmodule Screens.Elevator do
  @moduledoc """
  Exposes hand-authored data about elevator accessibility that is not (yet?) available in GTFS.
  """

  alias Screens.Facilities.Facility
  alias Screens.Report

  @enforce_keys ~w[id alternate_ids entering_redundancy exiting_redundancy exiting_summary]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: Facility.id(),
          alternate_ids: [Facility.id()],
          entering_redundancy: :nearby | :in_station | :shuttle | :other,
          exiting_redundancy: :nearby | :in_station | :other,
          exiting_summary: String.t()
        }

  @data_path :screens |> :code.priv_dir() |> Path.join("elevators.json")
  @data @data_path |> File.read!() |> Jason.decode!()
  @external_resource @data_path

  @callback get(Facility.id()) :: t() | nil
  def get(id) do
    case Map.get(@data, id) do
      nil ->
        Report.warning("elevator_redundancy_not_found", id: id)
        nil

      %{"alternate_ids" => alternate_ids, "summary" => summary} = entry ->
        %__MODULE__{
          id: id,
          alternate_ids: alternate_ids,
          entering_redundancy: entering_redundancy(entry),
          exiting_redundancy: exiting_redundancy(entry),
          exiting_summary: summary
        }
    end
  end

  defp entering_redundancy(%{"entering" => "1"}), do: :nearby
  defp entering_redundancy(%{"entering" => "2" <> _}), do: :in_station
  defp entering_redundancy(%{"entering" => "3B"}), do: :shuttle
  defp entering_redundancy(_other), do: :other

  defp exiting_redundancy(%{"exiting" => "1"}), do: :nearby
  defp exiting_redundancy(%{"exiting" => "2" <> _}), do: :in_station
  defp exiting_redundancy(_other), do: :other
end
