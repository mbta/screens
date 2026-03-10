defmodule Screens.Report do
  @moduledoc "Conveniences for logging to Splunk and Sentry."

  def error(tag, data \\ []), do: log(:error, tag, data)
  def warning(tag, data \\ []), do: log(:warning, tag, data)

  @spec log(:error | :warning, String.t(), Enumerable.t({String.Chars.t(), term()})) :: :ok
  defp log(level, tag, data) do
    Logster.log(level, [tag | data])
    _ = Sentry.capture_message(tag, extra: Map.new(data), level: level, result: :none)
    :ok
  end
end
