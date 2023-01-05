defmodule Screens.V2.WidgetInstance.DeparturesNoDataTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, BusShelter, GlEink}

  setup do
    %{
      widget: %WidgetInstance.DeparturesNoData{
        screen:
          struct(Screen, %{app_params: struct(BusShelter, %{alerts: %Alerts{stop_id: "1"}})}),
        show_alternatives?: true
      },
      gl_eink_widget: %WidgetInstance.DeparturesNoData{
        screen:
          struct(Screen, %{
            app_id: :gl_eink_v2,
            app_params: struct(GlEink, %{alerts: %Alerts{stop_id: "1"}})
          }),
        show_alternatives?: true
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{widget: widget} do
      assert [2] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns stop ID and `show_alternatives?`", %{widget: widget} do
      assert %{stop_id: "1", show_alternatives: true} == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns full_body_top_screen for gl_eink_v2", %{gl_eink_widget: gl_eink_widget} do
      assert [:full_main_content] == WidgetInstance.slot_names(gl_eink_widget)
    end

    test "returns main_content", %{widget: widget} do
      assert [:main_content] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns departures no data", %{widget: widget} do
      assert :departures_no_data == WidgetInstance.widget_type(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{widget: widget} do
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
      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns DeparturesNoDataView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.DeparturesNoDataView ==
               WidgetInstance.audio_view(widget)
    end
  end
end
