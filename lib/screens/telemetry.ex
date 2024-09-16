defmodule Screens.Telemetry do
  @moduledoc """
  `:telemetry` based span logging
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl GenServer
  def init(_) do
    handlers = [
      # V3 API
      log_span(~w[screens v3_api get_json]a, metadata: ~w[url cached]a),
      # Stops
      log_span(~w[screens stops stop fetch_stop_name]a, metadata: ~w[stop_id]),
      log_span(~w[screens stops stop fetch_location_context]a, metadata: ~w[app stop_id]),
      # Alerts
      log_span(~w[screens alerts alert fetch]a),
      # Routes
      log_span(~w[screens routes route fetch_routes_by_stop]a,
        metadata: ~w[stop_id type_filters]a
      ),
      # DUP Candidate Generator
      log_span(~w[screens v2 candidate_generator dup]a),
      log_span(~w[screens v2 candidate_generator dup departures_instances]a),
      log_span(~w[screens v2 candidate_generator dup departures get_section_data]a),
      log_span(~w[screens v2 candidate_generator dup departures get_sections_data]a),
      log_span(~w[screens v2 candidate_generator dup header_instances]a),
      log_span(~w[screens v2 candidate_generator dup alerts_instances]a),
      log_span(~w[screens v2 candidate_generator dup evergreen_content_instances]a),
      # New DUP Candidate Generator
      log_span(~w[screens v2 candidate_generator dup_new]a),
      log_span(~w[screens v2 candidate_generator dup_new departures_instances]a),
      log_span(~w[screens v2 candidate_generator dup_new evergreen_instances]a),
      log_span(~w[screens v2 candidate_generator dup_new header_instances]a),

      # events
      log_event(~w[hackney_pool]a,
        metadata: ~w[pool]a,
        measurements: ~w[free_count in_use_count no_socket queue_count take_rate]a
      )
    ]

    for {name, event_names, config} <- handlers do
      event_names = wrap_event_names(event_names)
      :ok = :telemetry.attach_many(name, event_names, &Screens.Telemetry.handle_event/4, config)
    end

    :ignore
  end

  @doc """
  Dispatch a series span events `start`, `stop`, and/or `exception`.

  Adds `span_id`, `parent_id`, and `correlation_id` to each event's metadata.

  Span IDs are tracked via process registry. If you want to link a span started
  in another process use `Screens.Telemetry.context/0` to generate the
  appropriate metadata and pass those values to via arguments or closure to
  the spawned process.
  """
  def span(name, meta \\ %{}, fun) do
    ctx = context()

    meta =
      ctx
      |> Map.merge(meta)
      |> Map.put_new_lazy(:span_id, &generate_span_id/0)

    previous_span_id = Process.put(:span_id, meta[:span_id])
    meta = Map.put_new(meta, :parent_id, previous_span_id)

    :telemetry.span(name, meta, fn ->
      result = fun.()
      Process.put(:span_id, previous_span_id)
      {result, meta}
    end)
  end

  @doc """
  Like `span/3` but requires a tuple of `{<return value>, <stop meta>}` to be
  returned from the passed function. The `<stop meta>` map will be merged into
  the meta map passed to `span_with_stop_meta/3`.
  """
  def span_with_stop_meta(name, meta \\ %{}, fun) do
    ctx = context()

    meta =
      ctx
      |> Map.merge(meta)
      |> Map.put_new_lazy(:span_id, &generate_span_id/0)

    previous_span_id = Process.put(:span_id, meta[:span_id])
    meta = Map.put_new(meta, :parent_id, previous_span_id)

    :telemetry.span(name, meta, fn ->
      {result, stop_meta} = fun.()
      Process.put(:span_id, previous_span_id)
      {result, Map.merge(meta, stop_meta)}
    end)
  end

  def context do
    ctx = %{correlation_id: get_correlation_id(), parent_id: get_parent_span_id()}
    request_id = Process.get(:request_id) || Logger.metadata()[:request_id]

    if request_id do
      Process.put(:request_id, request_id)
      Map.put(ctx, :request_id, request_id)
    else
      ctx
    end
  end

  def generate_span_id do
    binary = :crypto.strong_rand_bytes(12)
    Base.url_encode64(binary)
  end

  def handle_event(name, measurements, metadata, config) do
    measurements = Map.take(measurements, Map.get(config, :measurements, []))
    metadata = Map.take(metadata, Map.get(config, :metadata, []))

    Logger.info(fn ->
      measurements =
        Map.replace_lazy(
          measurements,
          :duration,
          &:erlang.convert_time_unit(&1, :native, :millisecond)
        )

      ["event=", Enum.join(name, "."), " ", to_log(metadata), " ", to_log(measurements)]
    end)
  end

  defp get_parent_span_id do
    Process.get(:span_id)
  end

  defp get_correlation_id do
    correlation_id = Process.get(:correlation_id)

    if correlation_id do
      correlation_id
    else
      correlation_id = generate_span_id()
      Process.put(:correlation_id, correlation_id)
      correlation_id
    end
  end

  @default_metadata ~w[span_id parent_id correlation_id request_id]a
  @default_measurements ~w[duration]a

  defp log_span(name, config \\ []) when is_list(name) do
    config = build_config(config)

    events = [
      name ++ [:start],
      name ++ [:stop],
      name ++ [:exception]
    ]

    {Enum.join(name, "."), events, config}
  end

  defp log_event(name, config) when is_list(name) do
    config = build_config(config)

    {Enum.join(name, "."), name, config}
  end

  defp build_config(config) do
    metadata =
      config
      |> Keyword.get(:metadata, [])
      |> Enum.concat(@default_metadata)
      |> Enum.uniq()

    measurements =
      config
      |> Keyword.get(:measurements, [])
      |> Enum.concat(@default_measurements)
      |> Enum.uniq()

    %{
      metadata: metadata,
      measurements: measurements
    }
  end

  defp to_log(enum) do
    for {k, v} <- enum do
      [to_string(k), "=", inspect(v)]
    end
    |> Enum.intersperse(" ")
  end

  defp wrap_event_names([[_ | _] | _] = event_names), do: event_names
  defp wrap_event_names(event_names), do: [event_names]
end
