defmodule Screens.SignsUiConfig.State.Parse do
  @moduledoc false

  def parse_config(%{"configured_headways" => headways, "signs" => signs}) do
    time_ranges =
      headways
      |> Enum.map(fn {id, data} -> {id, parse_time_ranges(data)} end)
      |> Enum.into(%{})

    signs_in_headway_mode = get_headway_mode_signs(signs)

    {signs_in_headway_mode, time_ranges}
  end

  defp parse_time_ranges(%{"off_peak" => off_peak, "peak" => peak}) do
    %{off_peak: parse_time_range(off_peak), peak: parse_time_range(peak)}
  end

  defp parse_time_range(%{"range_low" => low, "range_high" => high}), do: {low, high}

  defp get_headway_mode_signs(signs) do
    Enum.flat_map(signs, &get_headway_mode_sign/1)
  end

  defp get_headway_mode_sign(%{"id" => id, "mode" => "headway"}), do: [id]
  defp get_headway_mode_sign(_), do: []
end
