defmodule Screens.LogScreenData do
  @moduledoc false
  require Logger

  def log_api_response(screen_id, client_version, is_screen, response) do
    _ =
      if is_screen do
        Logger.info(
          "[screen api response] screen_id=#{screen_id} version=#{client_version} response_json=#{
            Jason.encode!(response)
          }"
        )
      end

    response
  end

  def log_departures(screen_id, is_screen, departures) do
    _ =
      case {is_screen, departures} do
        {false, _} -> nil
        {true, :error} -> Logger.info("[error fetching departures] screen_id=#{screen_id}")
        {true, {:ok, []}} -> Logger.info("[empty departures list] screen_id=#{screen_id}")
        _ -> nil
      end
  end
end
