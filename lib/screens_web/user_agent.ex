defmodule ScreensWeb.UserAgent do
  @moduledoc false

  def is_screen_conn?(%{params: %{"is_real_screen" => "true"}}), do: true
  def is_screen_conn?(_), do: false
end
