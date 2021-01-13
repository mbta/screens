defmodule Screens.Config.Dup.Override.FullscreenImage do
  @moduledoc false

  @type t :: %__MODULE__{
          image_url: String.t()
        }

  defstruct image_url: nil

  @spec from_json(map()) :: t()
  def from_json(%{"image_url" => image_url}) do
    %__MODULE__{image_url: image_url}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Map.put(:type, :image)
  end
end
