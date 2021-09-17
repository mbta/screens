defmodule Screens.Util.Assets do
  @moduledoc false

  def s3_asset_url(asset_path) do
    env = Application.get_env(:screens, :environment_name, "screens-prod")
    "https://mbta-screens.s3.amazonaws.com/#{env}/#{asset_path}"
  end
end
