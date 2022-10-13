defmodule Screens.ScreensByAlert.GenServer do
  @moduledoc """
  ScreensByAlert backend which uses a GenServer as the backend.
  """

  @behaviour Screens.ScreensByAlert.Behaviour
  use GenServer

  @type screen_id :: String.t()
  @type alert_id :: String.t()
  @type timestamp :: integer()

  @type state :: t | :error

  @type t :: %__MODULE__{
          screens_by_alert: %{alert_id() => list(screen_id())},
          screens_last_updated: %{screen_id() => timestamp()}
        }

  defstruct screens_by_alert: %{}, screens_last_updated: %{}

  @impl Screens.ScreensByAlert.Behaviour
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
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
  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call(
        {:put_data, screen_id, alert_ids},
        _from,
        %__MODULE__{
          screens_by_alert: screens_by_alert,
          screens_last_updated: screens_last_updated
        }
      ) do
    updated_screens_by_alert =
      alert_ids
      |> Enum.map(fn alert_id ->
        {alert_id, [screen_id]}
      end)
      |> Map.new()
      |> Map.merge(screens_by_alert, fn _key, screen_ids1, screen_ids2 ->
        Enum.uniq(screen_ids1 ++ screen_ids2)
      end)

    {:reply, :ok,
     %__MODULE__{
       screens_by_alert: updated_screens_by_alert,
       screens_last_updated: Map.put(screens_last_updated, screen_id, System.system_time(:second))
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
      screens_by_alert
      |> Map.get(alert_id, [])
      |> Enum.map(fn screen_id ->
        last_updated = Map.get(screens_last_updated, screen_id)
        {screen_id, last_updated}
      end)

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
end
