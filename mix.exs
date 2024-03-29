defmodule Screens.MixProject do
  use Mix.Project

  def project do
    [
      app: :screens,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :app_tree,
        flags: [
          :unmatched_returns
        ]
      ],
      test_coverage: [tool: LcovEx]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    apps = [:logger, :runtime_tools]

    apps =
      case Mix.env() do
        :prod -> [:ehmon | apps]
        :test -> [:credo | apps]
        _ -> apps
      end

    [
      mod: {Screens.Application, []},
      extra_applications: apps
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 3.0.4"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.17.1"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:gettext, "~> 0.22.1"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:cowboy, "== 2.10.0"},
      {:httpoison, "~> 1.8.0"},
      {:tzdata, "~> 1.1"},
      {:credo, "~> 1.6.0"},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.1"},
      {:ex_aws_secretsmanager, "~> 2.0", only: :prod},
      {:ex_aws_polly, "~> 0.4.0"},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:sweet_xml, "~> 0.7.0"},
      {:timex, "~> 3.6"},
      {:hackney, "== 1.17.4"},
      {:guardian, "~> 2.3.1"},
      {:ueberauth, "~> 0.10"},
      {:ueberauth_oidcc, "~> 0.3"},
      {:corsica, "~> 1.0"},
      {:lcov_ex, "~> 0.2", only: [:dev, :test], runtime: false},
      {:sentry, "~> 8.0"},
      {:retry, "~> 0.16.0"},
      {:stream_data, "~> 0.5", only: :test},
      {:memcachex, "~> 0.5.5"},
      {:aja, "~> 0.6.2"},
      {:telemetry_poller, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:screens_config,
       git: "https://github.com/mbta/screens-config-lib.git",
       ref: "e92136ed99cdacb0399e182038136f7729b5171f"}
    ]
  end
end
