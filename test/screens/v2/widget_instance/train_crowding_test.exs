defmodule Screens.V2.WidgetInstance.TrainCrowdingTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.V2.WidgetInstance.TrainCrowding, as: WidgetInstance
  alias Screens.Vehicles.Vehicle

  setup do
    config =
      struct(Screens.Config.Screen, %{
        app_params:
          struct(Screens.Config.V2.Triptych, %{
            train_crowding: %Screens.Config.V2.TrainCrowding{
              station_id: "place-masta",
              direction_id: 1,
              platform_position: 2.5,
              front_car_direction: "right",
              enabled: true
            }
          })
      })

    prediction = struct(Prediction, %{
      trip: %{
        headsign: "Oak Grove"
      },
      arrival_time: ~U[2023-08-16 21:10:00Z],
      vehicle: struct(Vehicle, %{
        stop_id: "10001",
        current_status: :incoming_at,
        carriages: [
          %{
            occupancy_status: :many_seats_available,
            occupancy_percentage: 20,
            carriage_sequence: 1
          },
          %{
            occupancy_status: :few_seats_available,
            occupancy_percentage: 80,
            carriage_sequence: 2
          },
          %{
            occupancy_status: :few_seats_available,
            occupancy_percentage: 85,
            carriage_sequence: 3
          },
          %{
            occupancy_status: :many_seats_available,
            occupancy_percentage: 25,
            carriage_sequence: 4
          },
          %{
            occupancy_status: :full,
            occupancy_percentage: 98,
            carriage_sequence: 5
          },
          %{
            occupancy_status: nil,
            occupancy_percentage: nil,
            carriage_sequence: 6
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
    test "serializes data", %{widget: widget} do
      expected = %{
        destination: "Oak Grove",
        arrival_time: "2023-08-16T21:10:00Z",
        crowding: [
          %{
            occupancy_status: :many_seats_available,
            occupancy_percentage: 20,
            carriage_sequence: 1
          },
          %{
            occupancy_status: :few_seats_available,
            occupancy_percentage: 80,
            carriage_sequence: 2
          },
          %{
            occupancy_status: :few_seats_available,
            occupancy_percentage: 85,
            carriage_sequence: 3
          },
          %{
            occupancy_status: :many_seats_available,
            occupancy_percentage: 25,
            carriage_sequence: 4
          },
          %{
            occupancy_status: :full,
            occupancy_percentage: 98,
            carriage_sequence: 5
          },
          %{
            occupancy_status: nil,
            occupancy_percentage: nil,
            carriage_sequence: 6
          }
        ],
        platform_position: 2.5,
        front_car_direction: "right",
        now: "2023-08-16T21:04:00Z"
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
