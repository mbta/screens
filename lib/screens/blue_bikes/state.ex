defmodule Screens.BlueBikes.State do
  @moduledoc """
  GenServer that server up-to-date BlueBikes station data.
  """

  alias Screens.BlueBikes
  alias Screens.BlueBikes.Parser

  use GenServer

  @type state :: t | :error

  @type t :: %__MODULE__{
          data: BlueBikes.t(),
          info_last_updated: pos_integer(),
          status_last_updated: pos_integer()
        }

  @type stations_by_id :: %{station_id => Station.t()}

  @type station_id :: String.t()

  @enforce_keys [:data, :info_last_updated, :status_last_updated]
  defstruct @enforce_keys

  # TTL specified by the API is 5 seconds
  @refresh_ms 5_000

  @api_client Application.compile_env!(:screens, :blue_bikes_api_client)

  # Client

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_stations(pid \\ __MODULE__, station_ids) when is_list(station_ids) do
    GenServer.call(pid, {:get_stations, station_ids})
  end

  def schedule_refresh(pid, ms \\ @refresh_ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  def put_state(pid, %__MODULE__{} = new_state) do
    GenServer.cast(pid, {:put_state, new_state})
  end

  # Server

  @impl true
  def init(:ok) do
    state =
      case fetch_data() do
        {:ok, stations_data, info_last_updated, status_last_updated} ->
          %__MODULE__{
            data: stations_data,
            info_last_updated: info_last_updated,
            status_last_updated: status_last_updated
          }

        :error ->
          :error
      end

    _ = schedule_refresh(self())
    {:ok, state}
  end

  @impl true
  def handle_call({:get_stations, station_ids}, _from, %__MODULE__{} = state) do
    {:reply, Map.take(state.data.stations_by_id, station_ids), state}
  end

  def handle_call({:get_stations, _station_ids}, _from, :error) do
    {:reply, [], :error}
  end

  @impl true
  def handle_cast({:put_state, %__MODULE__{} = new_state}, _old_state) do
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:refresh, state) do
    schedule_refresh(self())

    pid = self()

    {info_last_updated, status_last_updated} =
      case state do
        %__MODULE__{} -> {state.info_last_updated, state.status_last_updated}
        :error -> {0, 0}
      end

    # Asynchronously update state so that the server is not blocked while waiting for the request to complete.
    # If an error occurs during fetching/parsing, no problem. We'll try again soon.
    _ =
      Task.start(fn ->
        case fetch_data() do
          {:ok, stations_data, new_info_last_updated, new_status_last_updated} ->
            if new_info_last_updated > info_last_updated or
                 new_status_last_updated > status_last_updated do
              put_state(pid, %__MODULE__{
                data: stations_data,
                info_last_updated: new_info_last_updated,
                status_last_updated: new_status_last_updated
              })
            end

          :error ->
            nil
        end
      end)

    {:noreply, state}
  end

  defp fetch_data do
    with {:ok, station_information} <- @api_client.fetch_station_information(),
         {:ok, station_status} <- @api_client.fetch_station_status() do
      Parser.parse(station_information, station_status)
    end
  end
end
