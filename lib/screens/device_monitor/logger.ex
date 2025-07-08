defmodule Screens.DeviceMonitor.Logger do
  @moduledoc "Shared logging functions for device monitor servers."

  require Logger

  @spec log_data((-> [map()]), atom(), String.t()) :: :ok
  def log_data(fetch_fn, vendor_name, application_key) do
    if not is_nil(System.get_env(application_key)) do
      case fetch_fn.() do
        {:ok, data} -> Enum.each(data, &log_screen_entry(&1, vendor_name))
        :error -> nil
      end
    end

    :ok
  end

  defp log_screen_entry(screen_data, vendor_name) do
    log_message("#{vendor_name}_data_report", screen_data)
  end

  def log_message(message, data) do
    data_str = data |> Enum.map(&format_log_value/1) |> Enum.join(" ")
    Logger.info("#{message} #{data_str}")
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
