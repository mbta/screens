defmodule Screens.ScreensByAlert.GenServer do
  @moduledoc """
  ScreensByAlert backend which uses a GenServer as the backend.
  """

  @behaviour Screens.ScreensByAlert.Behaviour
  use GenServer

  @type screen_id :: String.t()
  @type alert_id :: String.t()
  @type timestamp :: integer()

  @type t :: %__MODULE__{
          screens_by_alert: %{
            alert_id() => %{
              screen_ids: list({screen_id(), timestamp()}),
              timer_reference: reference()
            }
          },
          screens_last_updated: %{
            screen_id() => %{last_updated: timestamp(), timer_reference: reference()}
          },
          screens_by_alert_ttl_seconds: non_neg_integer(),
          screens_last_updated_ttl_seconds: non_neg_integer(),
          screens_ttl_seconds: non_neg_integer()
        }

  @enforce_keys [
    :screens_by_alert_ttl_seconds,
    :screens_last_updated_ttl_seconds,
    :screens_ttl_seconds
  ]
  defstruct screens_by_alert: %{},
            screens_last_updated: %{},
            screens_by_alert_ttl_seconds: nil,
            screens_last_updated_ttl_seconds: nil,
            screens_ttl_seconds: nil

  ### Client

  @impl Screens.ScreensByAlert.Behaviour
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Screens.ScreensByAlert.Behaviour
  def put_data(pid \\ __MODULE__, screen_id, alert_ids, store_screen_id) do
    GenServer.cast(pid, {:put_data, screen_id, alert_ids, store_screen_id})
  end

  @impl Screens.ScreensByAlert.Behaviour
  def get_screens_by_alert(pid \\ __MODULE__, alert_ids) when is_list(alert_ids) do
    GenServer.call(pid, {:get_screens_by_alert, alert_ids})
  end

  @impl Screens.ScreensByAlert.Behaviour
  def get_screens_last_updated(pid \\ __MODULE__, screen_ids) when is_list(screen_ids) do
    GenServer.call(pid, {:get_screens_last_updated, screen_ids})
  end

  ### Server

  @impl GenServer
  def init(opts) do
    {:ok,
     %__MODULE__{
       screens_by_alert_ttl_seconds: opts[:screens_by_alert_ttl_seconds],
       screens_last_updated_ttl_seconds: opts[:screens_last_updated_ttl_seconds],
       screens_ttl_seconds: opts[:screens_ttl_seconds]
     }}
  end

  @impl GenServer
  def handle_cast({:put_data, screen_id, alert_ids, store_screen_id}, %__MODULE__{} = state) do
    now = System.system_time(:second)

    updated_screens_by_alert =
      alert_ids
      |> Enum.map(fn alert_id ->
        # Create a new timer to expire object in #{screens_by_alert_ttl_seconds} seconds
        reference =
          Process.send_after(
            self(),
            {:expire_alert, alert_id},
            state.screens_by_alert_ttl_seconds * 1000
          )

        # Allow for alerts to be stored in the cache, if valid and not visible on screens
        screen_id_list = if store_screen_id, do: [{screen_id, now}], else: []

        {alert_id, %{screen_ids: screen_id_list, timer_reference: reference}}
      end)
      |> Map.new()
      # Combine list of screen_ids if alert already exists.
      # Otherwise, create a new alert.
      |> Map.merge(state.screens_by_alert, fn
        _,
        %{screen_ids: screens1, timer_reference: new_timer},
        %{screen_ids: screens2, timer_reference: old_timer} ->
          _ = Process.cancel_timer(old_timer, async: true, info: false)

          updated_screen_ids =
            combine_screen_ids(screens1, screens2, state.screens_ttl_seconds, now)

          %{screen_ids: updated_screen_ids, timer_reference: new_timer}
      end)

    updated_screens_last_updated =
      get_updated_screens_last_updated(
        screen_id,
        state.screens_last_updated,
        state.screens_last_updated_ttl_seconds,
        now
      )

    {:noreply,
     %__MODULE__{
       state
       | screens_by_alert: updated_screens_by_alert,
         screens_last_updated: updated_screens_last_updated
     }}
  end

  @impl GenServer
  def handle_call(
        {:get_screens_by_alert, alert_ids},
        _from,
        %__MODULE__{} = state
      ) do
    now = System.system_time(:second)

    found_items =
      state.screens_by_alert
      |> Map.take(alert_ids)
      |> Map.new(fn {alert_id, %{screen_ids: timestamped_screen_ids}} ->
        screen_ids =
          timestamped_screen_ids
          # Reject expired screen_ids just in case.
          |> Enum.reject(fn {_id, created_at} ->
            created_at + state.screens_ttl_seconds < now
          end)
          |> Enum.map(fn {id, _created_at} -> id end)
          |> Enum.uniq()

        {alert_id, screen_ids}
      end)

    {:reply, found_items, state}
  end

  @impl GenServer
  def handle_call(
        {:get_screens_last_updated, screen_ids},
        _from,
        %__MODULE__{} = state
      ) do
    default_map = Map.new(screen_ids, &{&1, 0})

    found_items =
      state.screens_last_updated
      |> Map.take(screen_ids)
      |> Map.new(fn {id, data} -> {id, data.last_updated} end)

    result = Map.merge(default_map, found_items)

    {:reply, result, state}
  end

  @impl GenServer
  def handle_info(
        {:expire_alert, alert_id},
        %__MODULE__{} = state
      ) do
    {:noreply, %{state | screens_by_alert: Map.delete(state.screens_by_alert, alert_id)}}
  end

  @impl GenServer
  def handle_info(
        {:expire_last_updated, screen_id},
        %__MODULE__{} = state
      ) do
    {:noreply, %{state | screens_last_updated: Map.delete(state.screens_last_updated, screen_id)}}
  end

  defp get_updated_screens_last_updated(
         screen_id,
         screens_last_updated,
         screens_last_updated_ttl_seconds,
         now
       ) do
    existing_last_updated = Map.get(screens_last_updated, screen_id)

    # Cancel existing timer if screen_id was already in map.
    _ =
      if not is_nil(existing_last_updated) do
        Process.cancel_timer(existing_last_updated.timer_reference, async: true, info: false)
      end

    # Create a new timer to expire object in #{screens_last_updated_ttl_seconds} seconds
    reference =
      Process.send_after(
        self(),
        {:expire_last_updated, screen_id},
        screens_last_updated_ttl_seconds * 1000
      )

    # Overwrites previous last_updated if screen_id is already in map.

    Map.put(screens_last_updated, screen_id, %{
      last_updated: now,
      timer_reference: reference
    })
  end

  defp combine_screen_ids(new_screens, old_screens, ttl, now) do
    old_screens
    # Remove expired screen_ids based on TTL
    # as well as nil entries (which represent valid but not visible candidates)
    |> Enum.reject(fn {screen_id, created_at} ->
      created_at + ttl <= now || screen_id === nil
    end)
    # Combine this list with the new list
    |> Kernel.++(new_screens)
  end
end
