defmodule ScreensWeb.Router do
  use ScreensWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser_no_csrf do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :browser do
    plug :browser_no_csrf
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  pipeline :redirect_prod_http do
    if Application.compile_env(:screens, :redirect_http?) do
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
    pipe_through([:redirect_prod_http, :browser])

    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
  end

  scope "/admin", ScreensWeb do
    pipe_through [:redirect_prod_http, :browser, :auth, :ensure_auth, :ensure_screens_group]

    live_dashboard "/dashboard", metrics: ScreensWeb.Telemetry
    get("/*_", AdminController, :index)
  end

  scope "/api/admin", ScreensWeb do
    pipe_through [:redirect_prod_http, :api, :auth, :ensure_auth, :ensure_screens_group]

    get "/", AdminApiController, :index
    post "/screens/validate", AdminApiController, :validate
    post "/screens/validate/:id", AdminApiController, :validate
    post "/screens/confirm", AdminApiController, :confirm
    post "/screens/confirm/:id", AdminApiController, :confirm
    post "/refresh", AdminApiController, :refresh
    post "/devops", AdminApiController, :devops
    post "/maintenance", AdminApiController, :maintenance
    get "/images", AdminApiController, :list_images
    post "/images", AdminApiController, :upload_image
    delete "/images/:key", AdminApiController, :delete_image
  end

  scope "/v2", ScreensWeb.V2 do
    scope "/widget" do
      pipe_through [:redirect_prod_http, :browser_no_csrf]
      post "/:app_id", ScreenController, :widget
      get "/:app_id", ScreenController, :widget
    end

    scope "/screen" do
      pipe_through [:redirect_prod_http, :browser]

      get "/:id", ScreenController, :index
      get "/:id/simulation", ScreenController, :simulation

      get "/pending/:id", ScreenController, :index_pending
      get "/pending/:id/simulation", ScreenController, :simulation_pending
    end

    scope "/api/screen" do
      pipe_through [:redirect_prod_http, :api]

      get "/:id", ScreenApiController, :show
      get "/:id/simulation", ScreenApiController, :simulation

      get "/:id/dup", ScreenApiController, :show_dup

      get "/pending/:id", ScreenApiController, :show_pending
      get "/pending/:id/simulation", ScreenApiController, :simulation_pending
    end

    scope "/api/logging" do
      pipe_through [:redirect_prod_http, :api]

      post "/log_frontend_error", ScreenApiController, :log_frontend_error
      options "/log_frontend_error", ScreenApiController, :log_frontend_error_preflight
    end

    scope "/audio" do
      pipe_through [:redirect_prod_http, :api]

      get "/:id/readout.mp3", AudioController, :show
      get "/:id/volume", AudioController, :show_volume
      get "/:id/debug", AudioController, :debug
    end
  end

  scope "/api", ScreensWeb do
    pipe_through [:redirect_prod_http, :api]

    get "/screens_by_alert", ScreensByAlertController, :index
  end
end
