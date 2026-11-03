defmodule Screens.V3Api.CacheAudit do
  @moduledoc """
  Optional, low-frequency audit of static V3 API cache payloads.

  Sizes are external-term encoding estimates, not ETS or process memory. Entire
  responses (including included relationships) are counted by request endpoint.
  Scans are batched but traverse the whole cache and are not atomic snapshots.
  """

  alias Screens.V3Api.Cache.Static

  def child_specs(false), do: []

  def child_specs(true) do
    [
      Supervisor.child_spec(
        {:telemetry_poller,
         measurements: [{__MODULE__, :sample, []}], period: :timer.minutes(15)},
        id: :schedule_cache_audit_poller
      )
    ]
  end

  @doc "Logs a static cache sample without logging request parameters or response bodies."
  def sample(cache \\ Static) do
    started_at = System.monotonic_time(:millisecond)

    totals =
      cache.stream!([select: {:key, :value}], max_entries: 10)
      |> summarize()

    Logster.info(
      [event: "screens.v3_api.cache_audit", node: inspect(node())] ++
        Map.to_list(totals) ++
        [duration_ms: System.monotonic_time(:millisecond) - started_at]
    )

    :ok
  rescue
    error ->
      Logster.warning(
        event: "screens.v3_api.cache_audit_error",
        node: inspect(node()),
        error_type: inspect(error.__struct__)
      )

      :ok
  end

  @doc false
  def summarize(entries) do
    initial = %{
      schedule_entries: 0,
      other_entries: 0,
      schedule_external_bytes: 0,
      other_external_bytes: 0
    }

    totals =
      Enum.reduce(entries, initial, fn {{path, _params}, _value} = entry, totals ->
        {count_key, bytes_key} =
          if path == "schedules",
            do: {:schedule_entries, :schedule_external_bytes},
            else: {:other_entries, :other_external_bytes}

        totals
        |> Map.update!(count_key, &(&1 + 1))
        |> Map.update!(bytes_key, &(&1 + :erlang.external_size(entry)))
      end)

    total_bytes = totals.schedule_external_bytes + totals.other_external_bytes

    share = if total_bytes == 0, do: 0.0, else: totals.schedule_external_bytes / total_bytes
    Map.put(totals, :schedule_payload_share, share)
  end
end
