defmodule Screens.V2.WidgetInstance.NormalHeaderTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.V2.{GlEink, Header}
  alias Screens.V2.WidgetInstance

  setup do
    %{
      instance: %WidgetInstance.NormalHeader{
        icon: :logo,
        text: "Ruggles",
        time: ~U[2021-03-04 11:00:00Z]
      },
      dup_instance: %WidgetInstance.NormalHeader{
        screen: struct(ScreensConfig.Screen, %{app_id: :dup_v2}),
        icon: :logo,
        text: "Ruggles",
        time: ~U[2021-03-04 11:00:00Z]
      },
      mercury_eink_instance: %WidgetInstance.NormalHeader{
        screen:
          struct(ScreensConfig.Screen, %{
            app_id: :gl_eink_v2,
            vendor: :mercury,
            app_params: struct(GlEink, %{header: struct(Header.Destination)})
          }),
        icon: :green_e,
        text: "Medford/Tufts",
        time: ~U[2021-03-04 11:00:00Z]
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "does not return time if vendor is Mercury and app is GlEink", %{
      mercury_eink_instance: instance
    } do
      assert %{
               icon: :green_e,
               text: "Medford/Tufts",
               show_to: true
             } == WidgetInstance.serialize(instance)
    end

    test "returns serialized text, icon and time", %{instance: instance} do
      assert %{
               icon: :logo,
               text: "Ruggles",
               time: "2021-03-04T11:00:00Z",
               show_to: false
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns header slot", %{instance: instance} do
      assert [:header] == WidgetInstance.slot_names(instance)
    end

    test "returns DUP-specific header slot for DUP screens", %{dup_instance: dup_instance} do
      assert [:header_zero, :header_one, :header_two] == WidgetInstance.slot_names(dup_instance)
    end
  end

  describe "widget_type/1" do
    test "returns normal_header", %{instance: instance} do
      assert :normal_header == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns map with text key", %{instance: instance} do
      assert %{text: _} = WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{instance: instance} do
      assert [0] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true", %{instance: instance} do
      assert WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns NormalHeaderView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.NormalHeaderView == WidgetInstance.audio_view(instance)
    end
  end
end
