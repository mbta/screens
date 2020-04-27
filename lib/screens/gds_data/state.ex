defmodule Screens.GdsData.State do
  @moduledoc false

  use Screens.VendorData.State

  def do_log do
    Screens.GdsData.Logger.log_data()
    :ok
  end
end
