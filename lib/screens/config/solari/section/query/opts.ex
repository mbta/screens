defmodule Screens.Config.Solari.Section.Query.Opts do
  @type t :: %__MODULE__{
          include_schedules: boolean()
        }

  defstruct include_schedules: false

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    include_schedules = Map.get(json, "include_schedules", false)

    %__MODULE__{include_schedules: include_schedules}
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{include_schedules: include_schedules}) do
    %{"include_schedules" => include_schedules}
  end
end
