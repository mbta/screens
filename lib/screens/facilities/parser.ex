defmodule Screens.Facilities.Parser do
  @moduledoc false

  alias Screens.Facilities.Facility
  alias Screens.V3Api

  @types %{
    "BIKE_STORAGE" => :bike_storage,
    "BRIDGE_PLATE" => :bridge_plate,
    "ELECTRIC_CAR_CHARGERS" => :electric_car_chargers,
    "ELEVATED_SUBPLATFORM" => :elevated_subplatform,
    "ELEVATOR" => :elevator,
    "ESCALATOR" => :escalator,
    "FARE_MEDIA_ASSISTANCE_FACILITY" => :fare_media_assistance_facility,
    "FARE_MEDIA_ASSISTANT" => :fare_media_assistant,
    "FARE_VENDING_MACHINE" => :fare_vending_machine,
    "FARE_VENDING_RETAILER" => :fare_vending_retailer,
    "FULLY_ELEVATED_PLATFORM" => :fully_elevated_platform,
    "OTHER" => :other,
    "PARKING_AREA" => :parking_area,
    "PICK_DROP" => :pick_drop,
    "PORTABLE_BOARDING_LIFT" => :portable_boarding_lift,
    "RAMP" => :ramp,
    "TAXI_STAND" => :taxi_stand,
    "TICKET_WINDOW" => :ticket_window
  }

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "latitude" => latitude,
            "longitude" => longitude,
            "long_name" => long_name,
            "short_name" => short_name,
            "properties" => properties,
            "type" => type
          },
          "relationships" => %{"stop" => stop}
        },
        included
      ) do
    %Facility{
      id: id,
      excludes_stop_ids: Enum.flat_map(properties, &excluded_stop_id/1),
      latitude: latitude,
      longitude: longitude,
      long_name: long_name,
      short_name: short_name,
      stop: V3Api.Parser.included(stop, included, :unloaded),
      type: Map.get(@types, type, :unknown)
    }
  end

  defp excluded_stop_id(%{"name" => "excludes-stop", "value" => id}), do: [to_string(id)]
  defp excluded_stop_id(_property), do: []
end
