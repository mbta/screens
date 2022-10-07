defmodule Screens.ScreensByAlert.GenServer do
  @moduledoc """
  ScreensByAlert backend which uses a GenServer as the backend.
  """

  @behaviour Screens.ScreensByAlert.Behaviour
  use GenServer

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
    state = %{}

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:put_data, _screen_id, _alert_ids}, _from, state) do
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:get_screens_by_alert, _alert_id}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:get_screens_last_updated, _screen_id}, _from, state) do
    {:reply, 0, state}
  end
end
