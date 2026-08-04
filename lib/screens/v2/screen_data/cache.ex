defmodule Screens.V2.ScreenData.Cache do
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Nebulex.Adapters.Partitioned

  alias Nebulex.Distributed.RPC
  alias ScreensConfig.Screen
  alias Screens.V2.WidgetInstance

  @type key :: String.t()
  @type value :: [WidgetInstance.t()]

  @spec instances(key() | nil, module(), Screen.t()) :: value()
  def instances(nil, generator, screen), do: generate_local(nil, generator, screen)

  def instances(id, generator, screen) do
    case transaction(fn -> do_instances(id, generator, screen) end, keys: [id]) do
      {:ok, instances} -> instances
      {:error, reason} -> generate_local(id, generator, screen, reason)
    end
  end

  defp do_instances(id, generator, screen) do
    case fetch(id) do
      {:ok, instances} -> instances
      {:error, %Nebulex.KeyError{}} -> generate_remote(id, generator, screen)
      {:error, reason} -> generate_local(id, generator, screen, reason)
    end
  end

  defp generate_remote(id, generator, screen) do
    case find_node(id) do
      {:ok, n} when n == node() ->
        generate_local(id, generator, screen)

      {:ok, node} ->
        case RPC.call(node, __MODULE__, :instances, [id, generator, screen]) do
          {:error, reason} -> generate_local(id, generator, screen, reason)
          instances -> instances
        end

      {:error, reason} ->
        generate_local(id, generator, screen, reason)
    end
  end

  defp generate_local(id, generator, screen, reason \\ nil) do
    if not is_nil(reason), do: log_error(reason)
    screen |> generator.candidate_instances() |> tap(&update_cache(id, &1))
  end

  defp update_cache(id, instances) do
    with {:error, reason} <- put(id, instances, ttl: 5_000), do: log_error(reason)
  end

  defp log_error(reason), do: Logster.warning(["screen_data_cache_error", inspect(reason)])
end
