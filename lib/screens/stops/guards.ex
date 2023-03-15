defmodule Screens.Stops.Guards do
  @moduledoc """
  Useful guards for checking types of stop IDs.
  """

  @doc """
  Checks if a value is a string containing a parent station ID, like "place-bbsta".
  Parent stations represent collections of child stops, like "Back Bay Station" or "Nubian Station".

  This is only intended to be used as a guard--it will raise an exception
  if passed a string that's too short, or a non-string.

  (Guards are considered to fail when they return false or raise.)
  """
  defguard is_parent_station_id(str)
           when binary_part(str, 0, 6) == "place-"

  @doc """
  Checks if a value is a string containing a child stop ID, like "1216".
  Child stops represent individual vehicle berths, like bus stops, or platforms at stations (one child stop ID per platform x direction).

  This is only intended to be used as a guard--it will raise an exception
  if passed a string that's too short, or a non-string.

  (Guards are considered to fail when they return false or raise.)
  """
  defguard is_child_stop_id(str)
           when binary_part(str, 0, 1) in ~w[0 1 2 3 4 5 6 7 8 9]
end
