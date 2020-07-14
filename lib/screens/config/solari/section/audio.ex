defmodule Screens.Config.Solari.Section.Audio do
  @type t :: %__MODULE__{
          wayfinding: String.t() | nil
        }

  defstruct wayfinding: nil

  @spec from_json(map() | :default) :: t()
  def from_json(%{"wayfinding" => wayfinding}) do
    %__MODULE__{wayfinding: wayfinding}
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{wayfinding: wayfinding}) do
    %{"wayfinding" => wayfinding}
  end
end
