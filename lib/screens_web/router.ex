defmodule ScreensWeb.Router do
  use ScreensWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :redirect_prod_http do
    if Application.get_env(:screens, :redirect_http?) do
      plug(Plug.SSL, rewrite_on: [:x_forwarded_proto])
    end
  end

  pipeline :auth do
    plug(ScreensWeb.AuthManager.Pipeline)
  end

  pipeline :ensure_auth do
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  pipeline :ensure_screens_group do
    plug(ScreensWeb.EnsureScreensGroup)
  end

  scope "/", ScreensWeb do
    get "/_health", HealthController, :index
  end

  scope "/", ScreensWeb do
    pipe_through([:redirect_prod_http, :browser, :auth, :ensure_auth])

    get("/unauthorized", UnauthorizedController, :index)
  end

  scope "/auth", ScreensWeb do
    pipe_through([:browser])

    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
  end

  scope "/admin", ScreensWeb do
    pipe_through [:redirect_prod_http, :browser, :auth, :ensure_auth, :ensure_screens_group]

    get("/", AdminController, :index)
  end

  scope "/api/admin", ScreensWeb do
    pipe_through [:redirect_prod_http, :api, :browser, :auth, :ensure_auth, :ensure_screens_group]

    get "/", AdminApiController, :index
    post "/validate", AdminApiController, :validate
    post "/confirm", AdminApiController, :confirm
  end

  scope "/screen", ScreensWeb do
    pipe_through [:redirect_prod_http, :browser]

    get "/:id", ScreenController, :index
  end

  scope "/audit", ScreensWeb do
    pipe_through [:redirect_prod_http, :browser]

    get "/:id", ScreenController, :index
  end

  scope "/api/screen", ScreensWeb do
    pipe_through [:redirect_prod_http, :api, :browser]

    get "/:id", ScreenApiController, :show
  end

  scope "/audio", ScreensWeb do
    pipe_through [:api, :browser]

    get "/:id/readout.mp3", AudioController, :show

    get "/:id/debug", AudioController, :debug
  end

  scope "/alert_priority", ScreensWeb do
    pipe_through [:redirect_prod_http, :api, :browser]

    get "/:id", AlertPriorityController, :show
  end
end
