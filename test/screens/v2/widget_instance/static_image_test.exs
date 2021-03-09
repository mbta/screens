defmodule Screens.V2.WidgetInstance.StaticImageTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.StaticImage

  setup do
    priority = [2]

    image_url =
      "https://mbta-screens.s3.amazonaws.com/screens-prod/images/psa/e-ink-face-covering-psa.png"

    instance = %StaticImage{image_url: image_url, priority: priority}
    %{instance: instance}
  end

  describe "priority/1" do
    test "returns instance priority", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns instance url", %{instance: instance} do
      assert %{
               url:
                 "https://mbta-screens.s3.amazonaws.com/screens-prod/images/psa/e-ink-face-covering-psa.png"
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns slots for fullscreen size", %{instance: instance} do
      instance = %StaticImage{instance | size: :fullscreen}
      assert [:fullscreen] == WidgetInstance.slot_names(instance)
    end

    test "returns slots for large size", %{instance: instance} do
      instance = %StaticImage{instance | size: :large}
      assert [:large] == WidgetInstance.slot_names(instance)
    end

    test "returns slots for medium size", %{instance: instance} do
      instance = %StaticImage{instance | size: :medium}

      assert MapSet.new([:medium_right, :medium_left]) ==
               MapSet.new(WidgetInstance.slot_names(instance))
    end

    test "returns slots for small size", %{instance: instance} do
      instance = %StaticImage{instance | size: :small}

      assert MapSet.new([:small_upper_right, :small_lower_right]) ==
               MapSet.new(WidgetInstance.slot_names(instance))
    end
  end

  describe "widget_type/1" do
    test "returns static image", %{instance: instance} do
      assert :static_image == WidgetInstance.widget_type(instance)
    end
  end
end
