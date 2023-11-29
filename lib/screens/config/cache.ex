defmodule Screens.Config.Cache do
  @moduledoc """
  Functions to read data from a cached copy of the screens config.
  """

  alias Screens.Config
  alias ScreensConfig.Screen

  use Screens.Cache.Client, table: :screens_config

  def ok?, do: table_exists?()

  def refresh_if_loaded_before(screen_id) do
    with_table default: nil do
      [[last_deploy_timestamp]] = :ets.match(@table, {:last_deploy_timestamp, :"$1"})

      refresh_if_loaded_before =
        case :ets.match(@table, {screen_id, %{refresh_if_loaded_before: :"$1"}}) do
          [[timestamp]] -> timestamp
          [] -> nil
        end

      case {last_deploy_timestamp, refresh_if_loaded_before} do
        {nil, nil} ->
          nil

        {nil, refresh_if_loaded_before} ->
          refresh_if_loaded_before

        {last_deploy_timestamp, nil} ->
          last_deploy_timestamp

        {last_deploy_timestamp, refresh_if_loaded_before} ->
          Enum.max([last_deploy_timestamp, refresh_if_loaded_before], DateTime)
      end
    end
  end

  def last_deploy_timestamp do
    with_table do
      [[last_deploy_timestamp]] = :ets.match(@table, {:last_deploy_timestamp, :"$1"})
      last_deploy_timestamp
    end
  end

  def service_level(screen_id) do
    with_table default: 1 do
      case :ets.match(@table, {screen_id, %{app_params: %{service_level: :"$1"}}}) do
        [[service_level]] -> service_level
        [] -> 1
      end
    end
  end

  def disabled?(screen_id) do
    with_table default: false do
      case :ets.match(@table, {screen_id, %{disabled: :"$1"}}) do
        [[disabled]] -> disabled
        [] -> false
      end
    end
  end

  def screen(screen_id) do
    with_table default: nil do
      case :ets.match(@table, {screen_id, :"$1"}) do
        [[screen]] -> screen
        [] -> nil
      end
    end
  end

  def app_params(screen_id) do
    with_table default: nil do
      case :ets.match(@table, {screen_id, %{app_params: :"$1"}}) do
        [[app_params]] -> app_params
        [] -> nil
      end
    end
  end

  def devops do
    with_table default: nil do
      case :ets.match(@table, {:devops, :"$1"}) do
        [[devops]] -> devops
        [] -> nil
      end
    end
  end

  @doc """
  Returns a list of all screen IDs.
  """
  def screen_ids do
    with_table default: [] do
      # Not sure how to avoid matching against the struct this way.
      # Since this isn't a true pattern match, doing %Screen{} actually tries to instantiate the struct,
      # and we end up matching against all of its default field values,
      # or getting a compile error if it has any enforced keys.
      :ets.select(@table, [{{:"$1", %{__struct__: Screen}}, [{:is_binary, :"$1"}], [:"$1"]}])
    end
  end

  @doc """
  Returns a list of all screen IDs that satisfy the given filter.
  The filter function will be passed a tuple of {screen_id, screen_config} and should return true if that screen ID should be included in the results.
  """
  def screen_ids(filter_fn) do
    with_table default: [] do
      :ets.foldl(
        fn
          {screen_id, %Screen{}} = entry, acc when is_binary(screen_id) ->
            if filter_fn.(entry), do: [screen_id | acc], else: acc

          _, acc ->
            acc
        end,
        [],
        @table
      )
    end
  end

  def mode_disabled?(mode) do
    with_table default: false do
      case :ets.match(@table, {:devops, %{disabled_modes: :"$1"}}) do
        [[disabled_modes]] -> mode in disabled_modes
        [] -> false
      end
    end
  end

  @doc """
  Gets the full map of screen configurations.

  👉 WARNING: This function is expensive to run and returns a large amount of data.

  Unless you really need to get the entire map, try to use one of the other client functions, or define a new one
  that relies more on :ets.match / :ets.select to limit the size of data returned.
  """
  def screens do
    with_table do
      # TODO: Is it worth wrapping screen ID keys in {:screen, screen_id} to let the filtering step happen in :ets.match?
      @table
      |> :ets.tab2list()
      |> Enum.filter(fn {k, v} -> is_binary(k) and is_struct(v, Screen) end)
      |> Map.new()
    end
  end

  @doc """
  Gets the entire config struct.

  👉 WARNING: This function is expensive to run and returns a large amount of data.

  Unless you really need to get the entire config, try to use one of the other client functions, or define a new one
  that relies more on :ets.match / :ets.select to limit the size of data returned.
  """
  def config do
    with_table do
      @table
      |> :ets.tab2list()
      |> table_entries_to_config()
    end
  end

  defp table_entries_to_config(entries) do
    {{:devops, devops}, entries} = List.keytake(entries, :devops, 0)
    screen_entries = List.keydelete(entries, :last_deploy_timestamp, 0)

    %Config{screens: Map.new(screen_entries), devops: devops}
  end
end
