defmodule Screens.TestSupport.NormalSectionRowBuilder do
  @moduledoc """
  Provides a function that generates Route structs
  with less boilerplate for testing purposes.
  """
  alias Screens.Alerts.Alert
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.WidgetInstance.Departures.NormalSection.{AlertRow, HeadwayRow, SpecialTripRow}

  import Screens.TestSupport.InformedEntityBuilder

  def headway_row(opts) do
    %HeadwayRow{
      route: opts[:route],
      direction_id: opts[:direction_id],
      range: opts[:range],
      displayed_headsign: opts[:displayed_headsign]
    }
  end

  def special_trip_row(opts) do
    %SpecialTripRow{
      schedule:
        if is_nil(opts[:schedule]) do
          %Schedule{
            id: opts[:schedule_id],
            arrival_time: opts[:arrival_time],
            departure_time: opts[:departure_time],
            route: opts[:route],
            trip: %Trip{headsign: opts[:headsign], direction_id: opts[:direction_id]},
            stop:
              if opts[:stop_id] do
                %Stop{id: opts[:stop_id]}
              end
          }
        else
          opts[:schedule]
        end,
      special_trip_type: opts[:special_trip_type]
    }
  end

  def alert_row(opts) do
    %AlertRow{
      alert: %Alert{
        id: opts[:alert_id],
        effect: opts[:effect],
        active_period: opts[:active_period],
        informed_entities:
          opts[:informed_entity_ids]
          |> Enum.map(fn
            {id, route_id} -> ie(stop_id: id, route_id: route_id)
            id -> ie(stop_id: id)
          end)
      },
      representative_route: opts[:route],
      direction_id: opts[:direction_id],
      displayed_headsign: opts[:displayed_headsign],
      location: opts[:location]
    }
  end
end
