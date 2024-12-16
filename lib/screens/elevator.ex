defmodule Screens.Elevator do
  @moduledoc """
  Exposes hand-authored data about elevator accessibility that is not (yet?) available in GTFS.
  """

  alias Screens.Facilities.Facility
  alias Screens.Log

  @enforce_keys ~w[id alternate_ids redundancy]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: Facility.id(),
          alternate_ids: [Facility.id()],
          redundancy: redundancy()
        }

  @type redundancy :: :nearby | :in_station | {:other, summary :: String.t()}

  @data_path :screens |> :code.priv_dir() |> Path.join("elevators.json")
  @data @data_path |> File.read!() |> Jason.decode!()
  @external_resource @data_path

  @callback get(Facility.id()) :: t() | nil
  def get(id) do
    case Map.get(@data, id) do
      nil ->
        Log.warning("elevator_redundancy_not_found", id: id)
        nil

      %{"alternate_ids" => alternate_ids} = entry ->
        %__MODULE__{id: id, alternate_ids: alternate_ids, redundancy: redundancy(entry)}
    end
  end

  defp redundancy(%{"redundancy" => 1}), do: :nearby
  defp redundancy(%{"redundancy" => 2}), do: :in_station
  defp redundancy(%{"summary" => summary}), do: {:other, summary}
end
