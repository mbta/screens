defmodule Screens.V2.WidgetInstance.StaticImage do
  @moduledoc false

  alias Screens.V2.WidgetInstance.StaticImage

  defstruct screen: nil,
            image_url: nil,
            priority: nil,
            size: nil

  @type config :: Screens.V2.ScreenData.config()
  @type size :: :small | :medium | :large | :fullscreen

  @type t :: %__MODULE__{
          screen: config(),
          image_url: String.t(),
          priority: Screens.V2.WidgetInstance.priority(),
          size: size()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(%StaticImage{priority: priority}), do: priority
    def serialize(%StaticImage{image_url: image_url}), do: %{url: image_url}

    def slot_names(%StaticImage{screen: _screen, size: size}) do
      case size do
        :fullscreen -> [:fullscreen]
        :large -> [:large]
        :medium -> [:medium_left, :medium_right]
        :small -> [:small_upper_right, :small_lower_right]
      end
    end

    def widget_type(_instance), do: :static_image

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: ""

    def audio_sort_key(_instance), do: 0

    def audio_valid_candidate?(_instance), do: false
  end
end
