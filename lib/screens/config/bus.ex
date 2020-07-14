defmodule Screens.Config.Bus do
  alias Screens.Config.PsaList

  @type t :: %__MODULE__{
          stop_id: String.t(),
          psa_list: PsaList.t()
        }

  @default_stop_id ""

  defstruct stop_id: @default_stop_id,
            psa_list: PsaList.from_json(:default)

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    stop_id = Map.get(json, "stop_id", @default_stop_id)
    psa_list = Map.get(json, "psa_list", :default)

    %__MODULE__{
      stop_id: stop_id,
      psa_list: PsaList.from_json(psa_list)
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{stop_id: stop_id, psa_list: psa_list}) do
    %{
      "stop_id" => stop_id,
      "psa_list" => PsaList.to_json(psa_list)
    }
  end
end
