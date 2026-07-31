defmodule Screens.Alerts.KenmoreAlertHelper do
  @moduledoc """
    Kenmore specific alert helper that helps calculate which routes have applicable alerts
    by checking if the next Westbound stop is also informed. If it is, we assume that the
    Alert applies to the specific branch.

    NOTE: This module should eventually be removed/refactored to take into account Informed Entity
    activities rather than using this next stop workaround
  """
  alias Screens.Alerts.Alert

  @kenmore_stop_matchers [
    # Blanford Street
    %{branch: "b", stop: "70149"},
    # St Mary's
    %{branch: "c", stop: "70211"},
    # Fenway
    %{branch: "d", stop: "70187"}
  ]

  @spec kenmore_only_some_branches_affected?([Alert.t()], String.t()) :: boolean()
  def kenmore_only_some_branches_affected?(alerts, "place-kencl") do
    length =
      alerts
      |> get_branches_if_entity_matches_stop(@kenmore_stop_matchers)
      |> length()

    length > 0 and length < 3
  end

  def kenmore_only_some_branches_affected?(_alerts, _), do: false

  @spec get_branches_if_entity_matches_stop([Alert.t()], [%{branch: String.t(), stop: String.t()}]) ::
          [String.t()]
  def get_branches_if_entity_matches_stop(alerts, stop_matchers \\ @kenmore_stop_matchers) do
    alerts
    |> Enum.flat_map(&branches_if_entity_matches_stop(&1, stop_matchers))
    |> Enum.sort()
    |> Enum.uniq()
  end

  @spec reject_branches_if_entity_matches_stop([Alert.t()], [
          %{branch: String.t(), stop: String.t()}
        ]) :: [String.t()]
  def reject_branches_if_entity_matches_stop(alerts, stop_matchers \\ @kenmore_stop_matchers) do
    branches_to_match = Enum.map(stop_matchers, fn %{branch: branch} -> branch end)

    informed_branches =
      alerts
      |> Enum.flat_map(&branches_if_entity_matches_stop(&1, stop_matchers))
      |> Enum.sort()
      |> Enum.uniq()

    Enum.reject(branches_to_match, &(&1 in informed_branches))
  end

  # Given an alert, see if its informed entities match a list of stops-of-interest (called stop_matchers here).
  # If a stop matcher is found, the branch is added the the returned list.
  @spec branches_if_entity_matches_stop(Alert.t(), [%{branch: String.t(), stop: String.t()}]) ::
          [String.t()]
  defp branches_if_entity_matches_stop(%{informed_entities: informed_entities}, stop_matchers) do
    stop_matchers
    |> Enum.filter(fn stop_matcher ->
      Enum.any?(informed_entities, fn
        %{stop: %{id: stop_id}} -> stop_matcher.stop === stop_id
        %{stop: nil} -> false
      end)
    end)
    |> Enum.map(&Map.get(&1, :branch))
  end

  @spec branch_headsign(String.t(), boolean()) :: String.t()
  def branch_headsign(branch, false) do
    case(branch) do
      "b" -> "Boston College"
      "c" -> "Cleveland Cir"
      "d" -> "Riverside"
    end
  end

  def branch_headsign(branch, true) do
    case(branch) do
      "b" -> "Bost Coll"
      "c" -> "Clvlnd Cir"
      "d" -> "Riverside"
    end
  end
end
