defmodule Screens.VendorData.Logger do
  @moduledoc false

  require Logger

  def log_data(fetch_fn, vendor_name, application_key) do
    if not is_nil(Application.get_env(:screens, application_key)) do
      data = fetch_fn.()
      Enum.each(data, &log_screen_entry(&1, vendor_name))
    end
  end

  defp log_screen_entry(screen_data, vendor_name) do
    data_str =
      screen_data
      |> Enum.map(&format_log_value/1)
      |> Enum.join(" ")

    Logger.info("#{vendor_name}_data_report #{data_str}")
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
