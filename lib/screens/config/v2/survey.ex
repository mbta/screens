defmodule Screens.Config.V2.Survey do
  @moduledoc false

  @type t :: %__MODULE__{
          enabled: boolean(),
          medium_asset_path: String.t(),
          large_asset_path: String.t()
        }

  defstruct enabled: false,
            medium_asset_path: "",
            large_asset_path: ""

  use Screens.Config.Struct, with_default: true

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
