defmodule Screens.V3Api.CacheAudit do
  @moduledoc """
  Low-frequency audit of static V3 API and parsed schedule cache payloads.

  Sizes are external-term encoding estimates, not ETS or process memory. Entire
  responses (including included relationships) are counted by request endpoint.
  Scans are batched but traverse the whole cache and are not atomic snapshots.
  Distinct departing schedule and stop/route/direction counts use temporary maps
  shared across entries, so overlapping queries do not inflate coverage counts.
  """

  alias Screens.Schedules.{Dataset, Schedule, Store}
  alias Screens.V3Api.Cache.Static

  def child_specs(false), do: []

  def child_specs(true) do
    [
      Supervisor.child_spec(
        {:telemetry_poller,
         measurements: [{__MODULE__, :sample, []}, {__MODULE__, :sample_parsed, []}],
         period: :timer.seconds(15)},
        id: :schedule_cache_audit_poller
      )
    ]
  end

  @doc "Logs a static cache sample without logging request parameters or response bodies."
  def sample(cache \\ Static) do
    audit(cache, :api_static, &summarize/1)
  end

  @doc "Logs the same coverage metrics for the dedicated parsed schedule store."
  def sample_parsed(cache \\ Store.Cache) do
    audit(cache, :schedules, &summarize_parsed/1)
  end

  defp audit(cache, name, summarize) do
    started_at = System.monotonic_time(:millisecond)

    totals =
      cache.stream!([select: {:key, :value}], max_entries: 10)
      |> summarize.()

    Logster.info(
      [event: "screens.v3_api.cache_audit", cache: name, node: inspect(node())] ++
        Map.to_list(totals) ++
        [duration_ms: System.monotonic_time(:millisecond) - started_at]
    )

    :ok
  rescue
    error ->
      Logster.warning(
        event: "screens.v3_api.cache_audit_error",
        cache: name,
        node: inspect(node()),
        error_type: inspect(error.__struct__)
      )

      :ok
  end

  @doc false
  def summarize(entries) do
    summarize_entries(entries, :raw)
  end

  @doc false
  def summarize_parsed(entries) do
    summarize_entries(entries, :parsed)
  end

  defp summarize_entries(entries, strategy) do
    initial = %{
      schedule_entries: 0,
      other_entries: 0,
      schedule_external_bytes: 0,
      other_external_bytes: 0
    }

    coverage = %{
      schedule_records: 0,
      departure_records: 0,
      schedules: %{},
      stops: %{},
      routes: %{},
      directions: %{},
      combinations: %{}
    }

    {totals, coverage} =
      Enum.reduce(entries, {initial, coverage}, fn entry, {totals, coverage} ->
        {path, date, records} = records(entry, strategy)

        {count_key, bytes_key} =
          if path == "schedules",
            do: {:schedule_entries, :schedule_external_bytes},
            else: {:other_entries, :other_external_bytes}

        totals =
          totals
          |> Map.update!(count_key, &(&1 + 1))
          |> Map.update!(bytes_key, &(&1 + :erlang.external_size(entry)))

        coverage = Enum.reduce(records, coverage, &count_record(&1, date, &2))
        {totals, coverage}
      end)

    total_bytes = totals.schedule_external_bytes + totals.other_external_bytes

    share = if total_bytes == 0, do: 0.0, else: totals.schedule_external_bytes / total_bytes

    totals
    |> Map.put(:schedule_payload_share, share)
    |> Map.merge(%{
      schedule_records: coverage.schedule_records,
      departure_records: coverage.departure_records,
      distinct_schedules: map_size(coverage.schedules),
      distinct_stop_ids: map_size(coverage.stops),
      distinct_route_ids: map_size(coverage.routes),
      distinct_direction_ids: map_size(coverage.directions),
      distinct_stop_route_directions: map_size(coverage.combinations)
    })
  end

  defp records({{"schedules", params}, {_stale_at, {_modified, %{"data" => data}}}}, :raw)
       when is_list(data),
       do: {"schedules", params["filter[date]"], data}

  defp records({{path, _params}, _value}, :raw), do: {path, nil, []}

  defp records({{date, _params}, %Dataset{schedules: schedules}}, :parsed),
    do: {"schedules", Date.to_iso8601(date), schedules}

  defp count_record(record, date, coverage) do
    {id, trip, stop, route, direction, departure} = fields(record)
    coverage = Map.update!(coverage, :schedule_records, &(&1 + 1))

    if is_nil(departure) do
      coverage
    else
      # Identity includes service date so two days of the same schedule are not
      # collapsed. IDs deduplicate overlapping cached response/query scopes.
      identity = if id, do: {date, id}, else: {date, trip, stop, route, direction, departure}

      coverage = %{
        coverage
        | departure_records: coverage.departure_records + 1,
          schedules: Map.put(coverage.schedules, identity, true),
          stops: put_known(coverage.stops, stop),
          routes: put_known(coverage.routes, route),
          directions: put_known(coverage.directions, direction)
      }

      if is_nil(stop) or is_nil(route) or is_nil(direction) do
        coverage
      else
        %{coverage | combinations: Map.put(coverage.combinations, {stop, route, direction}, true)}
      end
    end
  end

  defp put_known(set, nil), do: set
  defp put_known(set, value), do: Map.put(set, value, true)

  defp fields(%Schedule{} = schedule) do
    {schedule.id, schedule.trip && schedule.trip.id, schedule.stop && schedule.stop.id,
     schedule.route && schedule.route.id, schedule.direction_id, schedule.departure_time}
  end

  defp fields(record) do
    {record["id"], get_in(record, ["relationships", "trip", "data", "id"]),
     get_in(record, ["relationships", "stop", "data", "id"]),
     get_in(record, ["relationships", "route", "data", "id"]),
     get_in(record, ["attributes", "direction_id"]),
     get_in(record, ["attributes", "departure_time"])}
  end
end
