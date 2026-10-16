defmodule Screens.Alerts.AlertTextUtil do
  @moduledoc """
  Text Util helper for getting the description for the end of an alert
  """

  alias Screens.Util

  @spec end_time_text(Alert.active_period(), DateTime.t()) :: String.t() | nil
  def end_time_text([{_start_time, nil} | _], _now), do: nil

  def end_time_text([{_start_time, end_time} | _], now) do
    end_time_eastern = Util.to_eastern(end_time)
    end_date = Util.service_date(end_time)
    now_date = Util.service_date(now)

    cond do
      end_date == now_date and
        end_time_eastern.hour >= 2 and
          end_time_eastern.hour < 5 ->
        "end of service"

      end_date == now_date ->
        Calendar.strftime(end_time_eastern, "%-I:%M %p")

      Date.diff(end_date, now_date) == 1 ->
        "tomorrow"

      Date.beginning_of_week(end_date) == Date.beginning_of_week(now_date) ->
        "this #{Calendar.strftime(end_date, "%A")}"

      true ->
        Calendar.strftime(end_date, "%b %-d")
    end
  end
end
