defmodule Screens.Telemetry do
  @moduledoc "Telemetry logging and polling."

  use Supervisor
  require Logger

  alias Screens.V3Api.Cache

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  @impl Supervisor
  def init(_) do
    handlers = [
      # example span to avoid unused function warnings; nothing emits this
      log_span(~w[screens example_event]a),

      # enable V3 API span logging (WARNING: high log volume)
      # log_span(~w[screens v3_api get_json]a, metadata: ~w[path query cache]a),

      # events
      log_event(~w[screens v3_api cache stats]a,
        metadata: ~w[cache]a,
        measurements: ~w[used total hits misses writes updates evictions expirations]a
      ),
      log_event(~w[screens v3_api pool stats]a,
        metadata: ~w[host]a,
        measurements: ~w[pool_size available_connections in_use_connections in_flight_requests]a
      )
    ]

    for {name, event_names, config} <- handlers do
      event_names = wrap_event_names(event_names)
      :ok = :telemetry.attach_many(name, event_names, &Screens.Telemetry.handle_event/4, config)
    end

    children = [
      {
        :telemetry_poller,
        measurements: [{__MODULE__, :cache_stats, []}, {__MODULE__, :pool_stats, []}],
        period: 10_000
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def cache_stats do
    for cache <- [Cache.Realtime, Cache.Static] do
      with {:ok, info} <- cache.info() do
        :telemetry.execute(
          ~w[screens v3_api cache stats]a,
          Map.merge(info.memory, info.stats),
          %{cache: info.server[:cache_name]}
        )
      end
    end
  end

  def pool_stats do
    with {:ok, status} <- Finch.get_pool_status(Screens.V3Api.Finch, :default) do
      for {{_scheme, host, _port}, pools} <- status, metrics <- pools do
        :telemetry.execute(~w[screens v3_api pool stats]a, metrics, %{host: host})
      end
    end
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
    Logster.info(fn ->
      measurements =
        measurements
        |> Map.take(Map.get(config, :measurements, []))
        |> Map.replace_lazy(:duration, &:erlang.convert_time_unit(&1, :native, :millisecond))
        |> Keyword.new()

      metadata = metadata |> Map.take(Map.get(config, :metadata, [])) |> Keyword.new()

      Enum.concat([[event: Enum.join(name, ".")], measurements, metadata])
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

  defp wrap_event_names([[_ | _] | _] = event_names), do: event_names
  defp wrap_event_names(event_names), do: [event_names]
end
