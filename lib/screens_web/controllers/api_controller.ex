defmodule ScreensWeb.ApiController do
  use ScreensWeb, :controller

  def show(conn, %{"id" => id}) do
    json(conn, %{screen_id: id})
  end
end
