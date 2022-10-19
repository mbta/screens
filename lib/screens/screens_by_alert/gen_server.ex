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
            alert_id() => %{screen_ids: list(screen_id()), created_at: timestamp()}
          },
          screens_last_updated: %{screen_id() => timestamp()},
          screens_by_alert_ttl_seconds: non_neg_integer(),
          screens_last_updated_ttl_seconds: non_neg_integer()
        }

  @enforce_keys [:screens_by_alert_ttl_seconds, :screens_last_updated_ttl_seconds]
  defstruct screens_by_alert: %{},
            screens_last_updated: %{},
            screens_by_alert_ttl_seconds: nil,
            screens_last_updated_ttl_seconds: nil

  @impl Screens.ScreensByAlert.Behaviour
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Screens.ScreensByAlert.Behaviour
  def put_data(pid \\ __MODULE__, screen_id, alert_ids) do
    GenServer.call(pid, {:put_data, screen_id, alert_ids})
  end

  @impl Screens.ScreensByAlert.Behaviour
  def get_screens_by_alert(pid \\ __MODULE__, alert_id) do
    GenServer.call(pid, {:get_screens_by_alert, alert_id})
  end

  @impl Screens.ScreensByAlert.Behaviour
  def get_screens_last_updated(pid \\ __MODULE__, screen_id) do
    GenServer.call(pid, {:get_screens_last_updated, screen_id})
  end

  @impl GenServer
  def init(opts) do
    {:ok,
     %__MODULE__{
       screens_by_alert_ttl_seconds: opts[:screens_by_alert_ttl_seconds],
       screens_last_updated_ttl_seconds: opts[:screens_last_updated_ttl_seconds]
     }}
  end

  @impl GenServer
  def handle_call(
        {:put_data, screen_id, alert_ids},
        _from,
        %__MODULE__{
          screens_by_alert: screens_by_alert,
          screens_last_updated: screens_last_updated,
          screens_by_alert_ttl_seconds: screens_by_alert_ttl_seconds,
          screens_last_updated_ttl_seconds: screens_last_updated_ttl_seconds
        } = state
      ) do
    updated_screens_by_alert =
      alert_ids
      |> Enum.map(fn alert_id ->
        # Check if object should expire in #{screens_by_alert_ttl_seconds} seconds
        Process.send_after(self(), {:expire_alert, alert_id}, screens_by_alert_ttl_seconds * 1000)
        {alert_id, %{screen_ids: [screen_id], created_at: System.system_time(:second)}}
      end)
      |> Map.new()
      # Combine list of screen_ids if alert already exists.
      # Otherwise, create a new alert.
      |> Map.merge(screens_by_alert, fn
        _, %{screen_ids: screens1, created_at: created_at}, %{screen_ids: screens2} ->
          %{screen_ids: Enum.uniq(screens1 ++ screens2), created_at: created_at}
      end)

    # Overwrites previous last_updated if screen_id is already in map.
    updated_screens_last_updated =
      Map.put(screens_last_updated, screen_id, System.system_time(:second))

    # Check if object should expire in #{screens_last_updated_ttl_seconds} seconds
    Process.send_after(
      self(),
      {:expire_last_updated, screen_id},
      screens_last_updated_ttl_seconds * 1000
    )

    {:reply, :ok,
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
        %__MODULE__{
          screens_by_alert: screens_by_alert,
          screens_last_updated: screens_last_updated
        } = state
      ) do
    result =
      case Map.get(screens_by_alert, alert_id) do
        %{screen_ids: screen_ids} ->
          Enum.map(screen_ids, fn
            screen_id when screen_ids != [] ->
              last_updated = Map.get(screens_last_updated, screen_id)
              {screen_id, last_updated}
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
        %__MODULE__{
          screens_last_updated: screens_last_updated
        } = state
      ) do
    {:reply, Map.get(screens_last_updated, screen_id), state}
  end

  @impl GenServer
  def handle_info(
        {:expire_alert, alert_id},
        %__MODULE__{screens_by_alert: screens_by_alert, screens_by_alert_ttl_seconds: ttl_seconds} =
          state
      ) do
    new_state =
      case Map.get(screens_by_alert, alert_id) do
        %{created_at: created_at} ->
          if created_at + ttl_seconds <= System.system_time(:second) do
            %{state | screens_by_alert: Map.delete(screens_by_alert, alert_id)}
          else
            state
          end
      end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(
        {:expire_last_updated, screen_id},
        %__MODULE__{
          screens_last_updated: screens_last_updated,
          screens_last_updated_ttl_seconds: ttl_seconds
        } = state
      ) do
    new_state =
      case Map.get(screens_last_updated, screen_id) do
        last_updated ->
          if last_updated + ttl_seconds <= System.system_time(:second) do
            %{state | screens_last_updated: Map.delete(screens_last_updated, screen_id)}
          else
            state
          end
      end

    {:noreply, new_state}
  end
end
