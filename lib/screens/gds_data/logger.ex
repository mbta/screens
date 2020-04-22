defmodule Screens.GdsData.Logger do
  @moduledoc false

  alias Screens.GdsData.Fetch

  def log_data do
    Screens.VendorData.Logger.log_data(
      &Fetch.fetch_data_for_current_day/0,
      "gds",
      :gds_dms_password
    )
  end
end
