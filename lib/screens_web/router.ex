defmodule ScreensWeb.Router do
  use ScreensWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ScreensWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/:id", PageController, :index
  end

  scope "/api", ScreensWeb do
    pipe_through [:api, :browser]

    get "/:id", ApiController, :show
  end

  scope "/alert_priority", ScreensWeb do
    pipe_through [:api, :browser]

    get "/:id", AlertPriorityController, :show
  end
end
