defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.TestSupport.CandidateGeneratorStub, as: Stub
  alias Screens.V2.ScreenData
  alias Screens.V2.WidgetInstance.{MockWidget, Placeholder}
  alias ScreensConfig.Screen

  import ExUnit.CaptureLog
  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @config_cache injected(Screens.Config.Cache)
  @parameters injected(Screens.V2.ScreenData.Parameters)

  require Stub

  Stub.candidate_generator(GrayGenerator, fn _ -> [placeholder(:gray)] end)
  Stub.candidate_generator(GreenGenerator, fn _ -> [placeholder(:green)] end)

  Stub.candidate_generator(CrashGenerator, fn %Screen{app_params: %{test_pid: pid}} ->
    send(pid, {:crash_running, self()})
    raise "oopsie"
  end)

  describe "get/2" do
    setup do
      stub(@parameters, :refresh_rate, fn _app_id -> 0 end)
      :ok
    end

    defp build_config(attrs) do
      struct!(
        %Screen{app_id: :test_app, app_params: %{}, device_id: "", name: "", vendor: ""},
        attrs
      )
    end

    test "gets widget data for a screen ID" do
      expect(@config_cache, :screen, fn "test_id" -> build_config(%{app_id: :test_app}) end)

      expect(
        @parameters,
        :candidate_generator,
        fn %Screen{app_id: :test_app}, nil -> GrayGenerator end
      )

      assert ScreenData.get("test_id") ==
               %{type: :normal, main: %{type: :placeholder, color: :gray, text: ""}}
    end

    test "generates widget data from a pending config" do
      deny(@config_cache, :screen, 1)

      expect(
        @parameters,
        :candidate_generator,
        fn %Screen{app_id: :test_app}, nil -> GrayGenerator end
      )

      assert ScreenData.get("test_id", pending_config: build_config(%{app_id: :test_app})) ==
               %{type: :normal, main: %{type: :placeholder, color: :gray, text: ""}}
    end

    test "selects a variant candidate generator" do
      expect(@config_cache, :screen, fn "test_id" -> build_config(%{app_id: :test_app}) end)

      expect(
        @parameters,
        :candidate_generator,
        fn %Screen{app_id: :test_app}, "test_variant" -> GrayGenerator end
      )

      assert ScreenData.get("test_id", generator_variant: "test_variant") ==
               %{type: :normal, main: %{type: :placeholder, color: :gray, text: ""}}
    end

    test "runs all variant generators in the background" do
      expect(@config_cache, :screen, fn "test_id" ->
        build_config(%{app_id: :test_app, app_params: %{test_pid: self()}})
      end)

      expect(@parameters, :variants, fn %Screen{app_id: :test_app} -> ["crash"] end)

      stub(
        @parameters,
        :candidate_generator,
        fn
          %Screen{app_id: :test_app}, nil -> GrayGenerator
          %Screen{app_id: :test_app}, "crash" -> CrashGenerator
        end
      )

      capture_log(fn ->
        assert %{type: :normal} = ScreenData.get("test_id", run_all_variants?: true)

        receive do
          {:crash_running, pid} ->
            ref = Process.monitor(pid)
            # Wait a bit longer than the default 100ms to avoid occasional timeouts
            assert_receive({:DOWN, ^ref, :process, _pid, _reason}, 200)
        end
      end)
    end
  end

  describe "variants/2" do
    setup do
      stub(@parameters, :refresh_rate, fn _app_id -> 0 end)
      :ok
    end

    test "gets widget data for all variants" do
      expect(@config_cache, :screen, fn "test_id" -> build_config(%{app_id: :test_app}) end)
      expect(@parameters, :variants, fn %Screen{app_id: :test_app} -> ["green"] end)

      stub(
        @parameters,
        :candidate_generator,
        fn
          %Screen{app_id: :test_app}, nil -> GrayGenerator
          %Screen{app_id: :test_app}, "green" -> GreenGenerator
        end
      )

      assert {%{main: %{color: :gray}}, %{"green" => %{main: %{color: :green}}}} =
               ScreenData.variants("test_id")
    end
  end

  describe "serialize/1" do
    test "serializes a hierarchical layout" do
      layout =
        {:screen,
         {:normal,
          [
            :main_content,
            {:flex_zone, {:two_medium, [:medium_left, :medium_right]}},
            :footer
          ]}}

      selected_widgets = %{
        main_content: %MockWidget{
          slot_names: [:main_content],
          widget_type: :departures,
          content: []
        },
        medium_left: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "face_covering.png"
        },
        medium_right: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "autopay.png"
        },
        footer: %MockWidget{
          slot_names: [:footer],
          widget_type: :normal_footer,
          content: "fare info"
        }
      }

      paging_metadata = %{flex_zone: {1, 3}, footer: {0, 2}}

      expected = %{
        type: :normal,
        main_content: %{type: :departures, content: []},
        flex_zone: %{
          type: :two_medium,
          page_index: 1,
          num_pages: 3,
          medium_left: %{type: :static_image, content: "face_covering.png"},
          medium_right: %{type: :static_image, content: "autopay.png"}
        },
        footer: %{type: :normal_footer, page_index: 0, num_pages: 2, content: "fare info"}
      }

      assert expected == ScreenData.serialize({layout, selected_widgets, paging_metadata})
    end
  end
end
