defmodule Screens.DeviceMonitor.Logger do
  @moduledoc "Shared logging functions for device monitor modules."

  alias Screens.Util

  require Logger

  @spec log_data((-> [map()]), atom(), String.t()) :: :ok
  def log_data(fetch_fn, vendor_name, application_key) do
    if System.get_env(application_key) do
      case fetch_fn.() do
        {:ok, data} -> Enum.each(data, &log_device_entry(&1, vendor_name))
        :error -> nil
      end
    else
      Logger.info("#{vendor_name}_report_disabled")
    end

    :ok
  end

  defp log_device_entry(data, vendor_name) do
    data_str = data |> Enum.map_join(" ", &Util.format_log_value/1)
    Logger.info("#{vendor_name}_data_report #{data_str}")
  end
end
