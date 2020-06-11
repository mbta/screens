defmodule Screens.Psa do
  @moduledoc false

  @eink_refresh_seconds 30
  @solari_refresh_seconds 15
  @solari_psa_period 3

  alias Screens.Override.State

  def current_bus_psa do
    choose_from_rotating_list(State.bus_psa_list(), @eink_refresh_seconds)
  end

  def current_green_line_psa do
    choose_from_rotating_list(State.green_line_psa_list(), @eink_refresh_seconds)
  end

  def current_solari_psa do
    # How often to change the selected PSA
    solari_psa_refresh_seconds = @solari_refresh_seconds * @solari_psa_period

    # Choose which PSA to show, if we're showing one this refresh
    solari_psa = choose_from_rotating_list(State.solari_psa_list(), solari_psa_refresh_seconds)

    # Return either the current PSA or nil
    solari_list = [solari_psa] ++ List.duplicate(nil, @solari_psa_period - 1)
    choose_from_rotating_list(solari_list, @solari_refresh_seconds)
  end

  defp choose_from_rotating_list([], _), do: nil
  defp choose_from_rotating_list([psa], _), do: psa

  defp choose_from_rotating_list(list, seconds_to_show) do
    t = DateTime.utc_now()
    seconds_since_midnight = t.hour * 60 * 60 + t.minute * 60 + t.second
    periods_since_midnight = div(seconds_since_midnight, seconds_to_show)
    current_index = rem(periods_since_midnight, length(list))
    Enum.at(list, current_index)
  end
end
