defmodule Screens.Alerts.Cache.Filter do
  @moduledoc """
  Logic to apply filters to a list of `Screens.Alerts.Alert` structs.
  """
  alias Screens.Stops.StopsToRoutes

  @default_activities ~w[BOARD EXIT RIDE]

  @type filter_opts() :: %{
          optional(:routes) => [String.t()],
          optional(:route_types) => [0..4 | nil],
          optional(:direction_id) => 0 | 1,
          optional(:stops) => [String.t()],
          optional(:activities) => [String.t()]
        }

  @spec filter_by([Screens.Alerts.Alert.t()], filter_opts()) :: [Screens.Alerts.Alert.t()]
  def filter_by(alerts, filter_opts) when filter_opts == %{}, do: alerts

  def filter_by(alerts, filter_opts) do
    {activities, filter_opts} = Map.pop(filter_opts, :activities, @default_activities)

    alerts
    |> filter(filter_opts)
    |> filter_by_informed_entity_activity(activities)
  end

  defp filter(alerts, filter_opts) when filter_opts == %{}, do: alerts

  defp filter(alerts, filter_opts) do
    filter_opts
    |> build_matchers()
    |> apply_matchers(alerts)
  end

  defp filter_by_informed_entity_activity(alerts, values) do
    values = MapSet.new(values)

    if MapSet.member?(values, "ALL") do
      alerts
    else
      alerts
      |> Enum.filter(fn alert ->
        Enum.any?(alert.informed_entities, fn informed_entity ->
          activities =
            informed_entity
            |> Map.get(:activities, [])
            |> MapSet.new()

          not MapSet.disjoint?(activities, values)
        end)
      end)
    end
  end

  def build_matchers(filter_opts) do
    filter_opts
    |> Enum.reduce([%{}], &build_matcher/2)
    |> reject_empty_matchers()
    |> Enum.uniq()
  end

  defp reject_empty_matchers(matchers) do
    matchers
    |> Enum.reject(fn matcher ->
      matcher
      |> Map.values()
      |> Enum.all?(&is_nil/1)
    end)
  end

  defp apply_matchers(matchers, alerts) do
    alerts
    |> Enum.filter(&matches?(&1, matchers))
  end

  defp build_matcher({:routes, values}, acc) when is_list(values) do
    matchers_for_values(acc, :route, values)
  end

  defp build_matcher({:route_types, values}, acc) when is_list(values) do
    matchers_for_values(acc, :route_type, values)
  end

  defp build_matcher({:direction_id, value}, acc) when value in [0, 1] do
    matchers_for_values(acc, :direction_id, [value])
  end

  defp build_matcher({:stops, values}, acc) when is_list(values) do
    route_ids = StopsToRoutes.stops_to_routes(values)

    route_matchers =
      for route_id <- route_ids,
          stop_id <- [nil | values] do
        %{route: route_id, stop: stop_id}
      end

    stop_matchers =
      for stop_id <- [nil | values] do
        %{stop: stop_id}
      end

    for matcher_list <- [route_matchers, stop_matchers],
        merge <- matcher_list,
        matcher <- acc do
      Map.merge(matcher, merge)
    end
  end

  defp matchers_for_values(acc, key, values) do
    for value <- values,
        matcher <- acc do
      Map.put(matcher, key, value)
    end
  end

  defp matches?(alert, matchers) when is_list(matchers) do
    matchers
    |> Enum.any?(&matches?(alert, &1))
  end

  defp matches?(alert, matcher) when is_map(matcher) do
    Enum.all?(matcher, &matches?(alert, &1))
  end

  defp matches?(alert, {key, value}) do
    Enum.any?(alert.informed_entities, &(Map.get(&1, key) == value))
  end
end
