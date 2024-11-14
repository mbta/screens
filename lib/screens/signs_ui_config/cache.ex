defmodule Screens.SignsUiConfig.Cache do
  @moduledoc """
  Functions to read data from a cached copy of the Signs UI config.
  """

  use Screens.Cache.Client, table: :signs_ui_config

  alias Screens.Headways

  @type entry :: {{:headways, headway_key()}, headway_values()}

  @type headway_key :: String.t()
  @type headway_values :: %{optional(atom()) => Headways.range()}

  @spec headways(headway_key()) :: headway_values()
  def headways(key) do
    with_table default: %{} do
      case :ets.match(@table, {{:headways, key}, :"$1"}) do
        [[headways]] -> headways
        [] -> %{}
      end
    end
  end
end
