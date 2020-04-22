defmodule Screens.MercuryData.State do
  @moduledoc false

  use Screens.VendorData.State

  @behaviour Screens.VendorData.State

  @impl true
  def do_log do
    Screens.MercuryData.Logger.log_data()
    :ok
  end
end
