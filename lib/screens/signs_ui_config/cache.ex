defmodule Screens.SignsUiConfig.Cache do
  @moduledoc """
  Functions to read data from a cached copy of the Signs UI config.
  """

  use Screens.Cache.Client, table: :signs_ui_config

  # Implementation notes:
  # Table entries use 2-part tuples as keys, to distinguish sign mode entries from time range entries.
  # They look like:
  # - Sign mode entry: {{:sign_mode, sign_id}, mode}
  # - Time ranges entry: {{:time_ranges, line_or_trunk}, %{off_peak: {low, high}, peak: {low, high}}}
  #
  # To look up the mode that a given sign is in for example, use:
  # [[mode]] = :ets.match(@table, {{:sign_mode, sign_id}, :"$1})

  def all_signs_in_headway_mode?(sign_ids) do
    all_signs_in_modes?(sign_ids, [:headway])
  end

  def all_signs_inactive?(sign_ids) do
    all_signs_in_modes?(sign_ids, [:off, :static_text])
  end

  def time_ranges(line_or_trunk) do
    with_table do
      case :ets.match(@table, {{:time_ranges, line_or_trunk}, :"$1"}) do
        [[ranges]] -> ranges
        [] -> nil
      end
    end
  end

  defp all_signs_in_modes?([], _modes), do: false

  defp all_signs_in_modes?(sign_ids, modes) do
    with_table do
      Enum.all?(sign_ids, fn sign_id ->
        case :ets.match(@table, {{:sign_mode, sign_id}, :"$1"}) do
          [[mode]] -> mode in modes
          [] -> false
        end
      end)
    end
  end
end
