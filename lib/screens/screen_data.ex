defmodule Screens.ScreenData do
  @moduledoc false

  alias Screens.LogScreenData

  @modules_by_app_id %{
    "bus_eink" => Screens.BusScreenData,
    "gl_eink_single" => Screens.GLScreenData,
    "gl_eink_double" => Screens.GLScreenData,
    "solari" => Screens.SolariScreenData
  }

  @disabled_response %{force_reload: false, success: false}

  @outdated_response %{force_reload: true}

  def by_screen_id(screen_id, is_screen, opts \\ []) do
    check_disabled = Keyword.get(opts, :check_disabled, false)

    client_version = Keyword.get(opts, :client_version, nil)
    check_version = not is_nil(client_version)

    response =
      cond do
        check_disabled and disabled?(screen_id) -> @disabled_response
        check_version and outdated?(client_version) -> @outdated_response
        true -> fetch_data(screen_id, is_screen)
      end

    _ = LogScreenData.log_api_response(screen_id, client_version, is_screen)

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
    Screens.Override.State.disabled?(String.to_integer(screen_id))
  end

  defp outdated?(client_version_str) do
    api_version = Screens.Override.State.api_version()

    client_version = String.to_integer(client_version_str)

    client_version < api_version
  end

  defp fetch_data(screen_id, is_screen) do
    app_id = app_id_from_screen_id(screen_id)

    screen_data_module = Map.get(@modules_by_app_id, app_id)
    screen_data_module.by_screen_id(screen_id, is_screen)
  end

  defp app_id_from_screen_id(screen_id) do
    :screens
    |> Application.get_env(:screen_data)
    |> Map.get(screen_id)
    |> Map.get(:app_id)
  end
end
