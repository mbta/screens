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
            alert_id() => %{screen_ids: list(screen_id()), timer_reference: reference()}
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
  def put_data(pid \\ __MODULE__, screen_id, alert_ids) do
    GenServer.cast(pid, {:put_data, screen_id, alert_ids})
  end

  @impl Screens.ScreensByAlert.Behaviour
  def get_screens_by_alert(pid \\ __MODULE__, alert_id) do
    GenServer.call(pid, {:get_screens_by_alert, alert_id})
  end

  @impl Screens.ScreensByAlert.Behaviour
  def get_screens_last_updated(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:get_screens_last_updated, screen_id})
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
  def handle_cast({:put_data, screen_id, alert_ids}, %__MODULE__{} = state) do
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

        {alert_id, %{screen_ids: [screen_id], timer_reference: reference}}
      end)
      |> Map.new()
      # Combine list of screen_ids if alert already exists.
      # Otherwise, create a new alert.
      |> Map.merge(state.screens_by_alert, fn
        _,
        %{screen_ids: screens1, timer_reference: new_timer},
        %{screen_ids: screens2, timer_reference: old_timer} ->
          _ = Process.cancel_timer(old_timer, async: true, info: false)
          %{screen_ids: Enum.uniq(screens1 ++ screens2), timer_reference: new_timer}
      end)

    updated_screens_last_updated =
      get_updated_screens_last_updated(
        screen_id,
        state.screens_last_updated,
        state.screens_last_updated_ttl_seconds
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
        {:get_screens_by_alert, alert_id},
        _from,
        %__MODULE__{} = state
      ) do
    result =
      case Map.get(state.screens_by_alert, alert_id) do
        %{screen_ids: screen_ids} ->
          Enum.map(screen_ids, fn screen_id ->
            {screen_id, state.screens_last_updated[screen_id].last_updated}
          end)

        # Alert either expired or never existed.
        _ ->
          []
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call(
        {:get_screens_last_updated, screen_id},
        _from,
        %__MODULE__{} = state
      ) do
    case Map.fetch(state.screens_last_updated, screen_id) do
      {:ok, screen_last_updated} -> {:reply, screen_last_updated.last_updated, state}
      :error -> {:reply, nil, state}
    end
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
         screens_last_updated_ttl_seconds
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
      last_updated: System.system_time(:second),
      timer_reference: reference
    })
  end
end
