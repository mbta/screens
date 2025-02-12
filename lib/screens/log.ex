defmodule Screens.Log do
  @moduledoc "Conveniences for logging to Splunk and Sentry."

  require Logger

  def error(tag, data \\ []), do: log(:error, tag, data)
  def warning(tag, data \\ []), do: log(:warning, tag, data)

  @spec log(:error | :warning, String.t(), Enumerable.t({String.Chars.t(), term()})) :: :ok
  defp log(level, tag, data) do
    Logger.log(
      level,
      tag <> " " <> Enum.map_join(data, " ", fn {key, value} -> "#{key}=#{inspect(value)}" end)
    )

    _ = Sentry.capture_message(tag, extra: Map.new(data), level: level, result: :none)

    :ok
  end
end
