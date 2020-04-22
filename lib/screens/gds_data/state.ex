defmodule Screens.GdsData.State do
  @moduledoc false

  use Screens.VendorData.State

  @behaviour Screens.VendorData.State

  @impl true
  def do_log do
    Screens.GdsData.Logger.log_data()
    :ok
  end
end
