defmodule Screens.Config.HeadwayConfig do
  @moduledoc false

  @typep sign_id :: String.t()
  @typep headway_id :: String.t()

  @type t :: %__MODULE__{
          sign_ids: [sign_id],
          headway_id: headway_id
        }

  defstruct sign_ids: [],
            headway_id: nil

  @spec from_json(map() | :default) :: t()
  def from_json(%{"sign_ids" => sign_ids, "headway_id" => headway_id}) do
    %__MODULE__{sign_ids: sign_ids, headway_id: headway_id}
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{sign_ids: sign_ids, headway_id: headway_id}) do
    %{sign_ids: sign_ids, headway_id: headway_id}
  end
end
