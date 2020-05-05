defmodule Screens.Psa do
  @moduledoc false

  alias Screens.Override.State

  def current_bus_psa do
    current_psa_from_list(State.bus_psa_list())
  end

  def current_green_line_psa do
    current_psa_from_list(State.green_line_psa_list())
  end

  defp current_psa_from_list(psa_list) do
    case psa_list do
      [] ->
        nil

      [psa] ->
        psa

      [_ | _] ->
        t = DateTime.utc_now()
        seconds_since_midnight = t.hour * 60 * 60 + t.minute * 60 + t.second
        periods_since_midnight = div(seconds_since_midnight, 30)
        psa_index = rem(periods_since_midnight, length(psa_list))
        Enum.at(psa_list, psa_index)
    end
  end
end
