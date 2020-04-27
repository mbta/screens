defmodule Screens.MercuryData.Logger do
  @moduledoc false

  alias Screens.MercuryData.Fetch

  def log_data do
    Screens.VendorData.Logger.log_data(&Fetch.fetch_data/0, :mercury, :mercury_api_key)
  end
end
