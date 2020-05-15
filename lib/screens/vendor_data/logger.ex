defmodule Screens.VendorData.Logger do
  @moduledoc false

  require Logger

  @spec log_data((() -> [map()]), atom(), atom()) :: :ok
  def log_data(fetch_fn, vendor_name, application_key) do
    if not is_nil(Application.get_env(:screens, application_key)) do
      case fetch_fn.() do
        {:ok, data} -> Enum.each(data, &log_screen_entry(&1, vendor_name))
        :error -> nil
      end
    end

    :ok
  end

  defp log_screen_entry(screen_data, vendor_name) do
    Screens.LogScreenData.log_message("#{vendor_name}_data_report", screen_data)
  end
end
