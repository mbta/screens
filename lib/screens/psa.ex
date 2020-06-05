defmodule Screens.Psa do
  @moduledoc false

  alias Screens.Override.State

  def current_bus_psa do
    current_psa_from_list(State.bus_psa_list(), 30)
  end

  def current_green_line_psa do
    current_psa_from_list(State.green_line_psa_list(), 30)
  end

  def show_solari_psa do
    current_psa_from_list([true, false, false], 15)
  end

  defp current_psa_from_list([], _), do: nil
  defp current_psa_from_list([psa], _), do: psa

  defp current_psa_from_list(psa_list, seconds_to_show) do
    t = DateTime.utc_now()
    seconds_since_midnight = t.hour * 60 * 60 + t.minute * 60 + t.second
    periods_since_midnight = div(seconds_since_midnight, seconds_to_show)
    psa_index = rem(periods_since_midnight, length(psa_list))
    Enum.at(psa_list, psa_index)
  end
end
