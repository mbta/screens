defmodule Screens.V2.WidgetInstance.TrainCrowdingTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.V2.WidgetInstance.TrainCrowding, as: WidgetInstance
  alias Screens.Vehicles.{Carriage, Vehicle}

  defp put_crowding_levels(widget, carriages) do
    put_in(widget.prediction.vehicle.carriages, carriages)
  end

  setup do
    config =
      struct(ScreensConfig.Screen, %{
        app_params:
          struct(ScreensConfig.V2.Triptych, %{
            train_crowding: %ScreensConfig.V2.TrainCrowding{
              station_id: "place-masta",
              direction_id: 1,
              platform_position: 3,
              front_car_direction: "right",
              enabled: true
            }
          })
      })

    prediction =
      struct(Prediction, %{
        trip: %{
          headsign: "Oak Grove"
        },
        vehicle:
          struct(Vehicle, %{
            stop_id: "10001",
            current_status: :incoming_at,
            carriages: [
              %Carriage{
                car_number: "1",
                occupancy_status: :crushed_standing_room_only,
                occupancy_percentage: 45
              },
              %Carriage{
                car_number: "2",
                occupancy_status: :few_seats_available,
                occupancy_percentage: 5
              },
              %Carriage{
                car_number: "3",
                occupancy_status: :standing_room_only,
                occupancy_percentage: 20
              },
              %Carriage{
                car_number: "4",
                occupancy_status: :many_seats_available,
                occupancy_percentage: 5
              },
              %Carriage{car_number: "5", occupancy_status: :full, occupancy_percentage: 45},
              %Carriage{
                car_number: "6",
                occupancy_status: :not_accepting_passengers,
                occupancy_percentage: -1
              }
            ]
          })
      })

    widget = %WidgetInstance{
      screen: config,
      prediction: prediction,
      now: ~U[2023-08-16 21:04:00Z]
    }

    %{widget: widget}
  end

  describe "serialize/1" do
    test "serializes data, 6/7 possible crowding levels", %{widget: widget} do
      expected = %{
        destination: "Oak Grove",
        crowding: [:crowded, :not_crowded, :some_crowding, :not_crowded, :crowded, :closed],
        platform_position: 3,
        front_car_direction: "right",
        now: "2023-08-16T21:04:00Z",
        show_identifiers: false
      }

      assert expected == WidgetInstance.serialize(widget)
    end

    test "serializes data, last crowding level (no_data)", %{widget: widget} do
      widget =
        put_crowding_levels(widget, [
          %Carriage{
            car_number: "1",
            occupancy_status: :no_data_available,
            occupancy_percentage: -1
          },
          %Carriage{
            car_number: "2",
            occupancy_status: :no_data_available,
            occupancy_percentage: -1
          },
          %Carriage{
            car_number: "3",
            occupancy_status: :standing_room_only,
            occupancy_percentage: 25
          },
          %Carriage{
            car_number: "4",
            occupancy_status: :many_seats_available,
            occupancy_percentage: 5
          },
          %Carriage{car_number: "5", occupancy_status: :full, occupancy_percentage: 45},
          %Carriage{
            car_number: "6",
            occupancy_status: :not_accepting_passengers,
            occupancy_percentage: -1
          }
        ])

      expected = %{
        destination: "Oak Grove",
        crowding: [:no_data, :no_data, :some_crowding, :not_crowded, :crowded, :closed],
        platform_position: 3,
        front_car_direction: "right",
        now: "2023-08-16T21:04:00Z",
        show_identifiers: false
      }

      assert expected == WidgetInstance.serialize(widget)
    end
  end

  describe "priority/1" do
    test "returns max priority", %{widget: widget} do
      assert [1] == WidgetInstance.priority(widget)
    end
  end

  describe "slot_names/1" do
    test "returns [:full_screen]", %{widget: widget} do
      assert [:full_screen] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :train_crowding", %{widget: widget} do
      assert :train_crowding == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns true", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty", %{widget: widget} do
      assert %{} == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{widget: widget} do
      assert [0] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{widget: widget} do
      assert not WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns nil", %{widget: widget} do
      assert nil == WidgetInstance.audio_view(widget)
    end
  end
end
