defmodule Screens.V2.WidgetInstance.StaticImageTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.StaticImage

  @priority [2]
  @image_url "https://mbta-screens.s3.amazonaws.com/screens-prod/images/psa/e-ink-face-covering-psa.png"
  @instance %StaticImage{image_url: @image_url, priority: @priority}

  describe "priority/1" do
    test "returns instance priority" do
      assert @priority == WidgetInstance.priority(@instance)
    end
  end

  describe "serialize/1" do
    test "returns instance url" do
      assert %{url: @image_url} == WidgetInstance.serialize(@instance)
    end
  end

  describe "slot_names/1" do
    test "returns slots for fullscreen size" do
      instance = %StaticImage{@instance | size: :fullscreen}
      assert [:fullscreen] == WidgetInstance.slot_names(instance)
    end

    test "returns slots for large size" do
      instance = %StaticImage{@instance | size: :large}
      assert [:large] == WidgetInstance.slot_names(instance)
    end

    test "returns slots for medium size" do
      instance = %StaticImage{@instance | size: :medium}

      assert MapSet.new([:medium_right, :medium_left]) ==
               MapSet.new(WidgetInstance.slot_names(instance))
    end

    test "returns slots for small size" do
      instance = %StaticImage{@instance | size: :small}

      assert MapSet.new([:small_upper_right, :small_lower_right]) ==
               MapSet.new(WidgetInstance.slot_names(instance))
    end
  end
end
