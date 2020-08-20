defmodule Screens.ScreenData do
  @moduledoc false

  alias Screens.LogScreenData
  alias Screens.Config.{Screen, State}

  @modules_by_app_id %{
    bus_eink: Screens.BusScreenData,
    gl_eink_single: Screens.GLScreenData,
    gl_eink_double: Screens.GLScreenData,
    solari: Screens.SolariScreenData
  }

  @disabled_response %{force_reload: false, success: false}

  @outdated_response %{force_reload: true}

  def by_screen_id(screen_id, is_screen, opts \\ []) do
    check_disabled = Keyword.get(opts, :check_disabled, false)

    last_refresh = Keyword.get(opts, :last_refresh, nil)
    check_outdated = not is_nil(last_refresh)

    response =
      cond do
        check_disabled and disabled?(screen_id) -> @disabled_response
        check_outdated and outdated?(screen_id, last_refresh) -> @outdated_response
        true -> fetch_data(screen_id, is_screen)
      end

    _ = LogScreenData.log_api_response(response, screen_id, last_refresh, is_screen)

    response
  end

  def by_screen_id_with_datetime(screen_id, datetime_str) do
    app_id = app_id_from_screen_id(screen_id)

    {:ok, naive} = Timex.parse(datetime_str, "{ISO:Extended}")
    {:ok, local} = DateTime.from_naive(naive, "America/New_York")
    {:ok, datetime} = DateTime.shift_zone(local, "Etc/UTC")
    screen_data_module = Map.get(@modules_by_app_id, app_id)
    screen_data_module.by_screen_id(screen_id, false, datetime)
  end

  defp disabled?(screen_id) do
    State.disabled?(screen_id)
  end

  defp outdated?(screen_id, client_refresh_timestamp) do
    {:ok, client_refresh_time, _} = DateTime.from_iso8601(client_refresh_timestamp)
    refresh_after_time = State.refresh_after(screen_id)

    case refresh_after_time do
      nil -> false
      _ -> DateTime.compare(client_refresh_time, refresh_after_time) == :lt
    end
  end

  defp fetch_data(screen_id, is_screen) do
    app_id = app_id_from_screen_id(screen_id)

    screen_data_module = Map.get(@modules_by_app_id, app_id)
    screen_data_module.by_screen_id(screen_id, is_screen)
  end

  defp app_id_from_screen_id(screen_id) do
    %Screen{app_id: app_id} = State.screen(screen_id)
    app_id
  end
end
