defmodule Screens.Log do
  @moduledoc "Conveniences for logging to Splunk and Sentry."

  require Logger

  def error(tag, data \\ []), do: log(:error, tag, data)
  def warning(tag, data \\ []), do: log(:warning, tag, data)
  def info(tag, data \\ []), do: log(:info, tag, data)

  @spec log(:error | :warning | :info, String.t(), Enumerable.t({String.Chars.t(), term()})) ::
          :ok
  defp log(level, tag, data) do
    Logger.log(
      level,
      tag <> " " <> Enum.map_join(data, " ", fn {key, value} -> "#{key}=#{inspect(value)}" end)
    )

    if level != :info do
      _ = Sentry.capture_message(tag, extra: Map.new(data), level: level, result: :none)
    end

    :ok
  end
end
