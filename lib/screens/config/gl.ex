defmodule Screens.Config.Gl do
  alias Screens.Config.PsaList

  @type t :: %__MODULE__{
          stop_id: String.t(),
          platform_id: String.t(),
          route_id: String.t(),
          direction_id: 0 | 1,
          headway_mode: boolean(),
          psa_list: PsaList.t()
        }

  @default_stop_id ""
  @default_platform_id ""
  @default_route_id ""
  @default_direction_id 0
  @default_headway_mode false

  defstruct stop_id: @default_stop_id,
            platform_id: @default_platform_id,
            route_id: @default_route_id,
            direction_id: @default_direction_id,
            headway_mode: @default_headway_mode,
            psa_list: PsaList.from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    stop_id = Map.get(json, "stop_id", @default_stop_id)
    platform_id = Map.get(json, "platform_id", @default_platform_id)
    route_id = Map.get(json, "route_id", @default_route_id)
    direction_id = Map.get(json, "direction_id", @default_direction_id)
    headway_mode = Map.get(json, "headway_mode", @default_headway_mode)
    psa_list = Map.get(json, "psa_list", :default)

    %__MODULE__{
      stop_id: stop_id,
      platform_id: platform_id,
      route_id: route_id,
      direction_id: direction_id,
      headway_mode: headway_mode,
      psa_list: PsaList.from_json(psa_list)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{
        stop_id: stop_id,
        platform_id: platform_id,
        route_id: route_id,
        direction_id: direction_id,
        headway_mode: headway_mode,
        psa_list: psa_list
      }) do
    %{
      "stop_id" => stop_id,
      "platform_id" => platform_id,
      "route_id" => route_id,
      "direction_id" => direction_id,
      "headway_mode" => headway_mode,
      "psa_list" => PsaList.to_json(psa_list)
    }
  end
end
