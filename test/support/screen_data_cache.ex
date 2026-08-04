defmodule Screens.TestSupport.ScreenDataCache do
  @moduledoc "Helpers for testing code that invokes the screen data cache."

  @doc "Pass through cache calls to the real module (for use when not testing the cache itself)."
  def passthrough(_context) do
    Mox.stub_with(Screens.V2.ScreenData.Cache.Store.Mock, Screens.V2.ScreenData.Cache.Store)
    :ok
  end
end
