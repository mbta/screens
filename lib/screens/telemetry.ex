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
      handle_span(~w[screens v3_api get_json]a, metadata: ~w[url cached]a),
      # Stops
      handle_span(~w[screens stops stop fetch_stop_name]a, metadata: ~w[stop_id]),
      handle_span(~w[screens stops stop fetch_location_context]a, metadata: ~w[app stop_id]),
      # Alerts
      handle_span(~w[screens alerts alert fetch]a),
      # Routes
      handle_span(~w[screens routes route fetch_routes_by_stop]a,
        metadata: ~w[stop_id type_filters]a
      ),
      # DUP Candidate Generator
      handle_span(~w[screens v2 candidate_generator dup departures_instances]a),
      handle_span(~w[screens v2 candidate_generator dup departures get_section_data]a),
      handle_span(~w[screens v2 candidate_generator dup departures get_sections_data]a),
      handle_span(~w[screens v2 candidate_generator dup header_instances]a),
      handle_span(~w[screens v2 candidate_generator dup alerts_instances]a),
      handle_span(~w[screens v2 candidate_generator dup evergreen_content_instances]a)
    ]

    for {name, event_names, config} <- handlers do
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

  def context do
    %{correlation_id: get_correlation_id(), parent_id: get_parent_span_id()}
  end

  def generate_span_id do
    binary = :crypto.strong_rand_bytes(12)
    Base.url_encode64(binary)
  end

  def handle_event(name, measurements, metadata, config) do
    measurements = Map.take(measurements, Map.get(config, :measurements, []))
    metadata = Map.take(metadata, Map.get(config, :metadata, []))

    Logger.info(fn ->
      [
        "[#{Enum.join(name, ".")}]",
        " ",
        to_log_iodata(metadata),
        " ",
        to_log_iodata(measurements)
      ]
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

  @default_metadata ~w[span_id parent_id correlation_id]a
  @default_measurements ~w[duration]a

  defp handle_span(name, config \\ []) when is_list(name) do
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

    config = %{
      metadata: metadata,
      measurements: measurements
    }

    events = [
      name ++ [:start],
      name ++ [:stop],
      name ++ [:exception]
    ]

    {Enum.join(name, "."), events, config}
  end

  defp to_log_iodata(enum) do
    for {k, v} <- enum do
      [to_string(k), "=", to_string(v)]
    end
    |> Enum.intersperse(" ")
  end
end
