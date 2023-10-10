defmodule Screens.LogScreenData do
  @moduledoc false
  require Logger
  alias ScreensConfig.Screen
  alias Screens.Config.State

  def log_page_load(screen_id, is_screen, screen_side \\ nil) do
    if is_screen do
      data =
        %{screen_id: screen_id, screen_name: screen_name_for_id(screen_id)}
        |> insert_screen_side(screen_side)

      log_message("[screen page load]", data)
    end
  end

  def log_data_request(
        screen_id,
        last_refresh,
        is_screen,
        params
      ) do
    requestor = params["requestor"]

    if is_screen or not is_nil(requestor) do
      screen_side = params["screen_side"]
      rotation_index = params["rotation_index"]
      triptych_pane = params["pane"]
      triptych_player_name = params["player_name"]
      ofm_app_package_version = params["version"]

      data =
        %{
          screen_id: screen_id,
          screen_name: screen_name_for_id(screen_id),
          last_refresh: last_refresh
        }
        |> insert_screen_side(screen_side)
        |> insert_requestor(requestor)
        |> insert_dup_rotation_index(rotation_index)
        |> insert_triptych_pane(triptych_pane)
        |> insert_triptych_player_name(triptych_player_name)
        |> insert_version(ofm_app_package_version)

      log_message("[screen data request]", data)
    end
  end

  def log_audio_request(screen_id, is_screen) do
    if is_screen do
      data = %{
        screen_id: screen_id,
        screen_name: screen_name_for_id(screen_id)
      }

      log_message("[screen audio request]", data)
    end
  end

  def log_frontend_error(screen_id, error_message, stack_trace) do
    data = %{
      screen_id: screen_id,
      error_message: error_message,
      stack_trace: stack_trace
    }

    log_message("[screen frontend error]", data)
  end

  def log_unrecognized_triptych_player(player_name) do
    log_message("[unrecognized triptych player name]", %{player_name: player_name})
  end

  def log_api_response(response, screen_id, last_refresh, is_screen, screen_side \\ nil)

  def log_api_response(
        %{status: status},
        screen_id,
        last_refresh,
        is_screen,
        screen_side
      ) do
    log_api_response_success(screen_id, last_refresh, is_screen, status, screen_side)
  end

  def log_api_response(status, screen_id, last_refresh, is_screen, screen_side) do
    log_api_response_success(screen_id, last_refresh, is_screen, status, screen_side)
  end

  defp log_api_response_success(screen_id, last_refresh, is_screen, status, screen_side) do
    if is_screen do
      data =
        %{
          screen_id: screen_id,
          screen_name: screen_name_for_id(screen_id),
          last_refresh: last_refresh
        }
        |> insert_screen_side(screen_side)

      log_message("[screen api response #{status}]", data)
    end

    :ok
  end

  def log_departures(_screen_id, false, _), do: nil

  def log_departures(screen_id, true, :error) do
    data = %{screen_id: screen_id, screen_name: screen_name_for_id(screen_id)}
    log_message("[error fetching departures]", data)
  end

  def log_departures(screen_id, true, {:ok, []}) do
    data = %{screen_id: screen_id, screen_name: screen_name_for_id(screen_id)}
    log_message("[empty departures list]", data)
  end

  def log_departures(_screen_id, true, {:ok, _}), do: nil

  def log_message(message, data) do
    data
    |> Enum.map_join(" ", &format_log_value/1)
    |> then(fn data_str ->
      Logger.info("#{message} #{data_str}")
    end)
  end

  defp format_log_value({key, value}) do
    value_str =
      case value do
        nil -> "null"
        _ -> "#{value}"
      end

    if String.contains?(value_str, " ") do
      "#{key}=\"#{value_str}\""
    else
      "#{key}=#{value_str}"
    end
  end

  defp screen_name_for_id(screen_id) do
    case State.screen(screen_id) do
      %Screen{name: name} -> name
      nil -> "UNKNOWN_SCREEN"
    end
  end

  defp insert_screen_side(data, nil), do: data
  defp insert_screen_side(data, screen_side), do: Map.put(data, :screen_side, screen_side)

  defp insert_requestor(data, nil), do: data
  defp insert_requestor(data, requestor), do: Map.put(data, :requestor, requestor)

  defp insert_dup_rotation_index(data, nil), do: data

  defp insert_dup_rotation_index(data, rotation_index),
    do: Map.put(data, :page_number, rotation_index)

  defp insert_triptych_pane(data, nil), do: data

  defp insert_triptych_pane(data, triptych_pane),
    do: Map.put(data, :triptych_pane, triptych_pane)

  defp insert_triptych_player_name(data, nil), do: data

  defp insert_triptych_player_name(data, triptych_player_name),
    do: Map.put(data, :triptych_player_name, triptych_player_name)

  defp insert_version(data, nil), do: data
  defp insert_version(data, version), do: Map.put(data, :ofm_app_package_version, version)
end
