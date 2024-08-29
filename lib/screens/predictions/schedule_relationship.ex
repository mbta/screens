defmodule Screens.Predictions.ScheduleRelationship do
  @moduledoc """
  Internal representation of the V3 API Prediction schedule relationship field.

  https://github.com/mbta/api/blob/8de1d89330077a0dcc739cd9123170d5913c11b5/apps/model/lib/model/prediction.ex#L32-L45
  """

  @type t :: :scheduled | :added | :cancelled | :no_data | :skipped | :unscheduled

  def parse(nil), do: :scheduled
  def parse("ADDED"), do: :added
  def parse("CANCELLED"), do: :cancelled
  def parse("NO_DATA"), do: :no_data
  def parse("SKIPPED"), do: :skipped
  def parse("UNSCHEDULED"), do: :unscheduled
end
