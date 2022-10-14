defmodule Screens.ScreensByAlert.Memcache do
  @moduledoc """
  ScreensByAlert backend which uses Memcache as a backend.
  """

  @behaviour Screens.ScreensByAlert.Behaviour

  @impl true
  def start_link(_opts \\ []) do
    {:ok, config} = Application.fetch_env(:screens, ScreensByAlert.Memcache)

    Memcache.start_link(config[:connection_opts])
  end

  @impl true
  def put_data(_screen_id, _alert_ids) do
    :ok
  end

  @impl true
  def get_screens_by_alert(_alert_id) do
    []
  end

  @impl true
  def get_screens_last_updated(_screen_id) do
    0
  end
end
