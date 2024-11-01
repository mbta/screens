defmodule Screens.SignsUiConfig.Parse do
  @moduledoc false

  alias Screens.SignsUiConfig.Cache

  @spec parse_config(map()) :: list(Cache.entry())
  def parse_config(%{"configured_headways" => headways}) do
    Enum.map(headways, fn {key, value} -> {{:headways, key}, parse_headways(value)} end)
  end

  defp parse_headways(map) do
    for {key, field} <- [
          off_peak: "off_peak",
          peak: "peak",
          saturday: "saturday",
          sunday: "sunday"
        ],
        range = parse_time_range(map[field]),
        into: %{} do
      {key, range}
    end
  end

  defp parse_time_range(%{"range_low" => low, "range_high" => high}), do: {low, high}
  defp parse_time_range(_), do: nil
end
