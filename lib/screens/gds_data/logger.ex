defmodule Screens.GdsData.Logger do
  @moduledoc false

  require Logger

  def log_data do
    if not is_nil(Application.get_env(:screens, :gds_dms_password)) do
      data = Screens.GdsData.Fetch.fetch_data_for_current_day()
      Enum.each(data, &log_screen_entry/1)
    end
  end

  defp log_screen_entry(screen_data) do
    data_str =
      screen_data
      |> Enum.map(&format_log_value/1)
      |> Enum.join(" ")

    Logger.info("gds_data_report #{data_str}")
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
end
