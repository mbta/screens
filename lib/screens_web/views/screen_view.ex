defmodule ScreensWeb.ScreenView do
  use ScreensWeb, :view

  def record_sentry?, do: Application.get_env(:screens, :record_sentry, false)
end
