defmodule Screens.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: ScreensWeb.PubSub},
      # Start the endpoint when the application starts
      ScreensWeb.Endpoint,
      # Starts a worker by calling: Screens.Worker.start_link(arg)
      # {Screens.Worker, arg},
      Screens.Config.State.Supervisor,
      Screens.SignsUiConfig.State.Supervisor,
      :hackney_pool.child_spec(:ex_aws_pool, []),
      :hackney_pool.child_spec(:blue_bikes_pool, []),
      :hackney_pool.child_spec(:api_v3_pool, max_connections: 100),
      {Screens.Stops.StationsWithRoutesAgent, %{}},
      # Turning this off because it's not in use, and the process is failing
      # {Screens.BlueBikes.State, name: Screens.BlueBikes.State},
      # Task supervisor for ScreensByAlert async updates
      # This supervisor is only used in deployment envs, but it's harmless to start it anyway in local dev.
      {Task.Supervisor, name: Screens.ScreensByAlert.Memcache.TaskSupervisor},
      # ScreensByAlert server process
      Screens.ScreensByAlert,
      # Task supervisor for ScreensByAlert self-refresh jobs
      {Task.Supervisor, name: Screens.ScreensByAlert.SelfRefreshRunner.TaskSupervisor},
      # ScreensByAlert self-refresh job runner
      {Screens.ScreensByAlert.SelfRefreshRunner, name: Screens.ScreensByAlert.SelfRefreshRunner}
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
