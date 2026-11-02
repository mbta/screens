defmodule Screens.Util.Assets do
  @moduledoc false

  @spec s3_asset_host() :: String.t()
  def s3_asset_host, do: "mbta-screens.s3.amazonaws.com"

  def s3_asset_url(nil), do: ""
  def s3_asset_url(""), do: ""

  def s3_asset_url(asset_path) do
    env = Application.get_env(:screens, :environment_name, "screens-dev")
    "https://#{s3_asset_host()}/#{env}/#{asset_path}"
  end
end
