defmodule Screens.Report do
  @moduledoc "Conveniences for logging to Splunk and Sentry."

  def error(tag, data \\ []), do: log(:error, tag, data)
  def warning(tag, data \\ []), do: log(:warning, tag, data)

  @spec log(:error | :warning, String.t(), keyword()) :: :ok
  defp log(level, tag, data) do
    Logster.log(level, [tag | data])
    extra = Logger.metadata() |> Keyword.merge(data) |> Map.new()
    _ = Sentry.capture_message(tag, extra: extra, level: level, result: :none)
    :ok
  end
end
