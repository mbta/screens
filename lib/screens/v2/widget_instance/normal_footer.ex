defmodule Screens.V2.WidgetInstance.NormalFooter do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalFooter

  defstruct screen: nil,
            url: nil

  @type config :: :ok
  @type t :: %__MODULE__{
          screen: config(),
          url: String.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%NormalFooter{url: url}) do
      %{url: url}
    end

    def slot_names(_instance), do: [:footer]

    def widget_type(_instance), do: :normal_footer
  end
end
