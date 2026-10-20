defmodule Screens.V2.WidgetInstance.Utils do
  @moduledoc """
  Utility functions to be shared by modules in the `Screens.V2.WidgetInstance` namespace.
  """

  alias ScreensConfig.Schedule

  @spec in_schedule_windows?([Schedule.t()], DateTime.t()) :: boolean()
  def in_schedule_windows?(schedule, now) when is_list(schedule) do
    schedule
    |> Enum.any?(fn
      %Schedule{start_dt: nil, end_dt: nil} ->
        true

      %Schedule{start_dt: start_dt, end_dt: nil} ->
        DateTime.compare(start_dt, now) in [:lt, :eq]

      %Schedule{start_dt: nil, end_dt: end_dt} ->
        DateTime.compare(end_dt, now) == :gt

      %Schedule{start_dt: start_dt, end_dt: end_dt} ->
        DateTime.compare(start_dt, now) in [:lt, :eq] and DateTime.compare(end_dt, now) == :gt
    end)
  end
end
