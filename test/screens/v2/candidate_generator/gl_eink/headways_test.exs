defmodule Screens.V2.CandidateGenerator.GlEink.HeadwaysTest do
  use ExUnit.Case, async: true

  alias Screens.Schedules.{Schedule, Store}
  alias Screens.V2.CandidateGenerator.GlEink.Headways

  test "uses cached previous-day closing schedules after midnight" do
    stop_id = inspect(make_ref())
    schedules = [%Schedule{arrival_time: ~U[2024-10-12 05:30:00Z]}]
    cache_schedules(stop_id, ~D[2024-10-11], schedules)

    assert 9 == Headways.by_route_id("Green-B", stop_id, 0, 1, ~U[2024-10-12 05:00:00Z])
  end

  test "uses the new service date at the four AM boundary for opening schedules" do
    stop_id = inspect(make_ref())
    cache_schedules(stop_id, ~D[2024-10-11], [])
    cache_schedules(stop_id, ~D[2024-10-12], [%Schedule{arrival_time: ~U[2024-10-12 08:00:00Z]}])

    assert 14 == Headways.by_route_id("Green-B", stop_id, 0, 1, ~U[2024-10-12 08:00:00Z])
  end

  defp cache_schedules(stop_id, date, schedules) do
    params = %{stop_ids: [stop_id], direction_id: 0}

    assert {:ok, _} =
             Store.fetch_dataset(params, date,
               acquire_fn: fn _, _, _ -> {:ok, schedules, nil} end
             )

    on_exit(fn -> Store.Cache.delete(Store.key(params, date)) end)
  end
end
