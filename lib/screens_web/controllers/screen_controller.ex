defmodule ScreensWeb.ScreenController do
  use ScreensWeb, :controller

  def show_image(conn, %{"filename" => filename}) do
    redirect(conn, external: Screens.Image.get_s3_url(filename))
  end
end
