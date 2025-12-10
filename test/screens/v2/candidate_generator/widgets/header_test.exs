defmodule Screens.V2.CandidateGenerator.Widgets.HeaderTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Widgets.Header, as: Generator
  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.{Header, Screen}

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @stop injected(Screens.Stops.Stop)

  @now ~U[2025-01-01 12:00:00Z]

  defp build_screen(app, params),
    do: struct(Screen, app_params: struct(app, params))

  describe "instances/2" do
    test "generates a header with stop name, time, and read_as" do
      screen =
        build_screen(Screen.BusShelter,
          header: %Header.StopName{stop_name: "foo", read_as: "foo_audio"}
        )

      assert Generator.instances(screen, @now) ==
               [%NormalHeader{screen: screen, read_as: "foo_audio", text: "foo", time: @now}]
    end

    test "generates a header with stop name as audio when not supplied" do
      screen =
        build_screen(Screen.BusShelter,
          header: %Header.StopName{stop_name: "foo"}
        )

      assert Generator.instances(screen, @now) ==
               [%NormalHeader{screen: screen, text: "foo", time: @now}]
    end

    test "fetches header text based on stop ID" do
      screen = build_screen(Screen.BusShelter, header: %Header.StopId{stop_id: "1"})
      expect(@stop, :fetch_stop_name, fn "1" -> "bar" end)

      assert Generator.instances(screen, @now) ==
               [%NormalHeader{screen: screen, read_as: "bar", text: "bar", time: @now}]
    end

    test "generates a copy of the header for each DUP rotation" do
      screen = build_screen(Screen.Dup, header: %Header.StopName{stop_name: "baz"})

      assert [%NormalHeader{}, %NormalHeader{}, %NormalHeader{}] =
               Generator.instances(screen, @now)
    end

    test "includes logo when app is Dup" do
      header = %Header.StopName{stop_name: ""}
      bus_shelter = build_screen(Screen.BusShelter, header: header)
      busway = build_screen(Screen.Busway, header: header)
      dup = build_screen(Screen.Dup, header: header)

      assert [%NormalHeader{icon: nil}] = Generator.instances(bus_shelter, @now)
      assert [%NormalHeader{icon: nil}] = Generator.instances(busway, @now)
      assert [%NormalHeader{icon: :logo} | _] = Generator.instances(dup, @now)
    end

    test "shows logo on Busway when we set include_logo_in_header field to true" do
      header = %Header.StopName{stop_name: ""}

      busway = build_screen(Screen.Busway, %{header: header, include_logo_in_header: true})

      assert [%NormalHeader{icon: :logo}] = Generator.instances(busway, @now)
    end
  end
end
