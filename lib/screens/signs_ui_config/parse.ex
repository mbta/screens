defmodule Screens.SignsUiConfig.Parse do
  @moduledoc false

  def parse_config(%{"configured_headways" => headways, "signs" => signs}) do
    time_ranges =
      headways
      |> Enum.map(fn {id, data} -> {id, parse_time_ranges(data)} end)
      |> Enum.into(%{})

    sign_modes = parse_sign_modes(signs)

    {sign_modes, time_ranges}
  end

  defp parse_time_ranges(map) do
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

  defp parse_sign_modes(signs) do
    signs
    |> Enum.map(fn {_, %{"id" => id, "mode" => mode}} -> {id, parse_sign_mode(mode)} end)
    |> Enum.into(%{})
  end

  for mode <- ~w[auto headway off static_text temporary_terminal]a do
    mode_string = Atom.to_string(mode)

    defp parse_sign_mode(unquote(mode_string)), do: unquote(mode)
  end

  defp parse_sign_mode(_), do: :unknown
end
