defmodule Screens.Elevator do
  @moduledoc """
  Exposes hand-authored data about elevator accessibility that is currently owned by the Screens
  team and not (yet?) available in GTFS.
  """

  alias Screens.Facilities.Facility
  alias Screens.Log

  @enforce_keys ~w[id redundancy]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{id: Facility.id(), redundancy: redundancy()}

  @type redundancy ::
          :nearby
          | :in_station
          | {:different_station, summary :: String.t()}
          | {:contact, summary :: String.t()}

  @data :screens
        |> :code.priv_dir()
        |> Path.join("elevators.json")
        |> File.read!()
        |> Jason.decode!()

  @callback get(Facility.id()) :: t() | nil
  def get(id) do
    case Map.get(@data, id) do
      %{"redundancy" => 1} ->
        %__MODULE__{id: id, redundancy: :nearby}

      %{"redundancy" => 2} ->
        %__MODULE__{id: id, redundancy: :in_station}

      %{"redundancy" => 3, "summary" => summary} ->
        %__MODULE__{id: id, redundancy: {:different_station, summary}}

      %{"redundancy" => 4, "summary" => summary} ->
        %__MODULE__{id: id, redundancy: {:contact, summary}}

      _other ->
        Log.warning("elevator_redundancy_not_found", id: id)
        nil
    end
  end
end
