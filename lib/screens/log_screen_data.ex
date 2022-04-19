defmodule Screens.LogScreenData do
  @moduledoc false
  require Logger
  alias Screens.Config.{Screen, State}

  def log_page_load(screen_id, is_screen, screen_side \\ nil) do
    if is_screen do
      data = %{screen_id: screen_id, screen_name: screen_name_for_id(screen_id)}

      if not is_nil(screen_side) do
        Map.put(data, :screen_side, screen_side)
      end

      log_message("[screen page load]", data)
    end
  end

  def log_data_request(screen_id, last_refresh, is_screen, screen_side \\ nil) do
    if is_screen do
      data = %{
        screen_id: screen_id,
        screen_name: screen_name_for_id(screen_id),
        last_refresh: last_refresh
      }

      if not is_nil(screen_side) do
        Map.put(data, :screen_side, screen_side)
      end

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

  def log_api_response(response, screen_id, last_refresh, is_screen, screen_side \\ nil)

  def log_api_response(
        %{force_reload: true},
        screen_id,
        last_refresh,
        is_screen,
        screen_side
      ) do
    log_api_response_success(screen_id, last_refresh, is_screen, screen_side)
  end

  def log_api_response(%{success: true}, screen_id, last_refresh, is_screen, screen_side) do
    log_api_response_success(screen_id, last_refresh, is_screen, screen_side)
  end

  def log_api_response(_response, _screen_id, _last_refresh, _is_screen, _screen_side) do
    :ok
  end

  defp log_api_response_success(screen_id, last_refresh, is_screen, screen_side) do
    _ =
      if is_screen do
        data = %{
          screen_id: screen_id,
          screen_name: screen_name_for_id(screen_id),
          last_refresh: last_refresh
        }

        if not is_nil(screen_side) do
          Map.put(data, :screen_side, screen_side)
        end

        log_message("[screen api response success]", data)
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
    %Screen{name: name} = State.screen(screen_id)
    name
  end
end
