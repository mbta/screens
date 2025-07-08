defmodule Screens.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = [
      {Screens.Cache.Owner, engine_module: Screens.Config.Cache.Engine},
      {Screens.Cache.Owner, engine_module: Screens.SignsUiConfig.Cache.Engine},
      :hackney_pool.child_spec(:api_v3_pool, max_connections: 50),
      Screens.V3Api.Cache.Realtime,
      Screens.V3Api.Cache.Static,
      # Task supervisor for ScreensByAlert async updates
      {Task.Supervisor, name: Screens.ScreensByAlert.Memcache.TaskSupervisor},
      # ScreensByAlert server process
      Screens.ScreensByAlert,
      # Task supervisor for ScreensByAlert self-refresh jobs
      {Task.Supervisor, name: Screens.ScreensByAlert.SelfRefreshRunner.TaskSupervisor},
      # ScreensByAlert self-refresh job runner
      {Screens.ScreensByAlert.SelfRefreshRunner, name: Screens.ScreensByAlert.SelfRefreshRunner},
      # Task supervisor for parallel running of candidate generator variants
      {Task.Supervisor, name: Screens.V2.ScreenData.ParallelRunSupervisor},
      {Task.Supervisor, name: Screens.DeviceMonitor.Supervisor},
      Screens.DeviceMonitor,
      Screens.LastTrip,
      Screens.Telemetry,
      {Phoenix.PubSub, name: ScreensWeb.PubSub},
      ScreensWeb.Endpoint,
      Screens.Health
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Screens.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ScreensWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
