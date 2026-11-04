defmodule Screens.V3Api.CacheAuditTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Screens.Routes.Route
  alias Screens.Schedules.{Dataset, Schedule}
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V3Api.CacheAudit

  defmodule TestCache do
    use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local
  end

  defmodule FailingCache do
    def stream!(_, _), do: raise("private response details")
  end

  test "empty caches have zero counts and share" do
    assert CacheAudit.summarize([]) == %{
             schedule_entries: 0,
             other_entries: 0,
             schedule_external_bytes: 0,
             other_external_bytes: 0,
             schedule_payload_share: 0.0,
             schedule_records: 0,
             departure_records: 0,
             distinct_schedules: 0,
             distinct_stop_ids: 0,
             distinct_route_ids: 0,
             distinct_direction_ids: 0,
             distinct_stop_route_directions: 0
           }
  end

  test "sizes entire schedule responses including included relationships and cache wrappers" do
    response = %{
      "data" => [%{"type" => "schedule", "id" => "schedule-1"}],
      "included" => [%{"type" => "trip", "id" => "trip-1"}]
    }

    schedule = {{"schedules", %{"filter[stop]" => "70001"}}, {0, {"modified", response}}}
    other = {{"stops", %{}}, {0, {"modified", %{"data" => []}}}}
    totals = CacheAudit.summarize([schedule, other])

    assert totals.schedule_entries == 1
    assert totals.other_entries == 1
    assert totals.schedule_external_bytes == :erlang.external_size(schedule)
    assert totals.other_external_bytes == :erlang.external_size(other)

    assert totals.schedule_payload_share ==
             :erlang.external_size(schedule) /
               (:erlang.external_size(schedule) + :erlang.external_size(other))

    {key, {stale_at, {modified, body}}} = schedule
    without_included = {key, {stale_at, {modified, Map.delete(body, "included")}}}

    assert totals.schedule_external_bytes > :erlang.external_size(without_included)
  end

  test "schedule-only caches have a share of one" do
    assert %{schedule_payload_share: 1.0} =
             CacheAudit.summarize([{{"schedules", %{}}, %{}}])
  end

  test "compares raw and parsed departure coverage across overlapping scopes and dates" do
    first = schedule("one", "stop-1", "Green-B", 0)
    second = schedule("two", "stop-1", "Green-B", 0)
    third = schedule("three", "stop-2", "Green-C", 1)
    arrival_only = %{first | id: "terminal", departure_time: nil}

    raw = [
      raw_entry("2024-10-11", "a", [first, second, third, arrival_only]),
      raw_entry("2024-10-11", "b", [first]),
      raw_entry("2024-10-12", "a", [first])
    ]

    parsed = [
      parsed_entry(~D[2024-10-11], "a", [first, second, third]),
      parsed_entry(~D[2024-10-11], "b", [first]),
      parsed_entry(~D[2024-10-12], "a", [first])
    ]

    raw_totals = CacheAudit.summarize(raw)
    parsed_totals = CacheAudit.summarize_parsed(parsed)
    assert raw_totals.schedule_records == 6
    assert parsed_totals.schedule_records == 5

    for totals <- [raw_totals, parsed_totals] do
      assert totals.departure_records == 5
      assert totals.distinct_schedules == 4
      assert totals.distinct_stop_ids == 2
      assert totals.distinct_route_ids == 2
      assert totals.distinct_direction_ids == 2
      assert totals.distinct_stop_route_directions == 2
    end
  end

  test "missing fields do not create fictitious coverage combinations" do
    record = %Schedule{id: "one", departure_time: ~U[2024-10-11 12:00:00Z]}
    totals = CacheAudit.summarize_parsed([parsed_entry(~D[2024-10-11], "a", [record])])
    assert totals.distinct_schedules == 1
    assert totals.distinct_stop_ids == 0
    assert totals.distinct_route_ids == 0
    assert totals.distinct_direction_ids == 0
    assert totals.distinct_stop_route_directions == 0
    assert CacheAudit.summarize_parsed([]).distinct_schedules == 0
  end

  test "missing schedule IDs deduplicate using departure identity" do
    first = %{schedule("one", "stop-1", "Green-B", 0) | id: nil}
    second = %{first | departure_time: DateTime.add(first.departure_time, 10, :minute)}

    entries = [
      parsed_entry(~D[2024-10-11], "a", [first, second]),
      parsed_entry(~D[2024-10-11], "b", [first])
    ]

    totals = CacheAudit.summarize_parsed(entries)
    assert totals.departure_records == 3
    assert totals.distinct_schedules == 2
    assert totals.distinct_stop_route_directions == 1
  end

  test "parsed audit logs cache identity and counts but never schedule IDs" do
    previous_level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: previous_level) end)
    start_supervised!(TestCache)
    record = schedule("private-id", "private-stop", "private-route", 0)
    {key, dataset} = parsed_entry(~D[2024-10-11], "scope", [record])
    assert :ok = TestCache.put(key, dataset)
    log = capture_log([level: :info], fn -> assert :ok = CacheAudit.sample_parsed(TestCache) end)
    assert log =~ "cache=schedules"
    assert log =~ "distinct_stop_route_directions=1"
    assert log =~ "distinct_schedules=1"
    refute log =~ "private-"
  end

  defp schedule(id, stop, route, direction) do
    %Schedule{
      id: id,
      trip: %Trip{id: "trip-#{id}"},
      stop: %Stop{id: stop},
      route: %Route{id: route},
      direction_id: direction,
      departure_time: ~U[2024-10-11 12:00:00Z]
    }
  end

  defp raw_entry(date, scope, schedules) do
    data =
      Enum.map(schedules, fn s ->
        %{
          "id" => s.id,
          "attributes" => %{
            "direction_id" => s.direction_id,
            "departure_time" => s.departure_time
          },
          "relationships" => %{
            "trip" => %{"data" => %{"id" => s.trip.id}},
            "stop" => %{"data" => %{"id" => s.stop.id}},
            "route" => %{"data" => %{"id" => s.route.id}}
          }
        }
      end)

    {{"schedules", %{"filter[date]" => date, "scope" => scope}},
     {0, {"modified", %{"data" => data}}}}
  end

  defp parsed_entry(date, scope, schedules) do
    {{date, %{scope: scope}},
     %Dataset{
       schedules: schedules,
       service_date: date,
       coverage: %{},
       generation: make_ref(),
       retrieved_at: ~U[2024-10-11 12:00:00Z],
       validated_at: ~U[2024-10-11 12:00:00Z]
     }}
  end

  test "streams resident entries and logs aggregates without private data" do
    previous_level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: previous_level) end)

    start_supervised!(TestCache)
    key = {"schedules", %{"filter[stop]" => "private-stop"}}
    assert :ok = TestCache.put(key, "private-response")

    log =
      capture_log([level: :info], fn ->
        assert :ok = CacheAudit.sample(TestCache)
      end)

    assert log =~ "screens.v3_api.cache_audit"
    assert log =~ "cache=api_static"
    assert log =~ "schedule_entries=1"
    assert log =~ "schedule_external_bytes="
    assert log =~ "duration_ms="
    refute log =~ "private-stop"
    refute log =~ "private-response"
    assert {:ok, "private-response"} = TestCache.fetch(key)
  end

  test "scan errors are logged without propagating or leaking exception details" do
    log = capture_log(fn -> assert :ok = CacheAudit.sample(FailingCache) end)

    assert log =~ "screens.v3_api.cache_audit_error"
    assert log =~ "RuntimeError"
    refute log =~ "private response details"
  end

  test "polling is optional and separate from the ten-second cache stats poller" do
    assert CacheAudit.child_specs(false) == []

    assert [%{id: :schedule_cache_audit_poller, start: {module, :start_link, [opts]}}] =
             CacheAudit.child_specs(true)

    assert module == :telemetry_poller
    assert opts[:period] == :timer.minutes(15)
    assert opts[:measurements] == [{CacheAudit, :sample, []}, {CacheAudit, :sample_parsed, []}]
  end
end
