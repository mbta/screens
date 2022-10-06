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
      {Screens.BlueBikes.State, name: Screens.BlueBikes.State}
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

  @doc """
  Fetches a configuration value and raises if missing.

  ## Examples

      iex> Screens.Application.config(ScreensByAlert.Memcache, :connection_opts)
      [
        namespace: "localhost:4000",
        hostname: "localhost"
      ]
  """
  def config(root_key, sub_key) do
    root_key
    |> config()
    |> Keyword.fetch(sub_key)
    |> case do
      {:ok, val} ->
        val

      :error ->
        raise """
        missing :screens mix configuration for key #{sub_key}
        """
    end
  end

  def config(root_key) do
    Application.fetch_env!(:screens, root_key)
  end
end
