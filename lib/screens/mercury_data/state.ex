defmodule Screens.MercuryData.State do
  @moduledoc false

  use Screens.VendorData.State

  def do_log do
    Screens.MercuryData.Logger.log_data()
    :ok
  end
end
