defmodule Screens.ScreenApiResponseCache do
  use Nebulex.Cache, otp_app: :screens, adapter: Nebulex.Adapters.Local
end
