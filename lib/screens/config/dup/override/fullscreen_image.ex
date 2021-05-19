defmodule Screens.Config.Dup.Override.FullscreenImage do
  @moduledoc false

  @type t :: %__MODULE__{
          image_url: String.t()
        }

  defstruct image_url: nil

  use Screens.Config.Struct

  def to_json(%__MODULE__{} = t) do
    t
    |> super()
    |> Map.put(:type, :image)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
