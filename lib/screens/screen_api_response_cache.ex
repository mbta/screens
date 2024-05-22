defmodule Screens.ScreenApiResponseCache do
  @moduledoc """
  Cache used to reduce the number of duplicate API calls.
  """

  use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local
end
