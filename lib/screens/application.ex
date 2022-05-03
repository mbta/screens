defmodule Screens.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Logger.add_backend(Sentry.LoggerBackend)

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
      :hackney_pool.child_spec(:api_v3_pool, []),
      {Screens.Stops.StationsWithRoutesAgent, %{}}
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
