defmodule Screens.MixProject do
  use Mix.Project

  def project do
    [
      app: :screens,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
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
    apps = [:logger, :runtime_tools, :hackney_telemetry]

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

  defp aliases do
    [
      "credo.ci": "credo --strict --checks-without-tag formatter"
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.20.17"},
      {:phoenix_live_dashboard, "~> 0.8.4"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:gettext, "~> 0.26.1"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:cowboy, "== 2.12.0"},
      {:httpoison, "~> 2.2.1"},
      {:tzdata, "~> 1.1"},
      {:credo, "~> 1.7.7"},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.1"},
      {:ex_aws_polly, "~> 0.5.0"},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:sweet_xml, "~> 0.7.0"},
      {:timex, "~> 3.6"},
      {:hackney, "== 1.20.1"},
      {:guardian, "~> 2.3.1"},
      {:ueberauth, "~> 0.10"},
      {:ueberauth_oidcc, "~> 0.4"},
      {:corsica, "~> 2.1"},
      {:lcov_ex, "~> 0.2", only: [:dev, :test], runtime: false},
      {:sentry, "~> 10.4"},
      {:retry, "~> 0.18.0"},
      {:mox, "~> 1.0", only: :test},
      {:stream_data, "~> 1.1", only: :test},
      {:memcachex, "~> 0.5.5"},
      {:aja, "~> 0.7.0"},
      {:telemetry, "~> 1.2"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:screens_config,
       git: "https://github.com/mbta/screens-config-lib.git",
       ref: "7dbb2b9b3da0154ca9128c7c2a4ab30d18501290"},
      {:nebulex, "~> 2.6"},
      {:remote_ip, "~> 1.2"},
      {:hackney_telemetry, "~> 0.2.0"},
      {:ex_cldr_messages, "~> 1.0"},
      {:recon, "~> 2.5.6"}
    ]
  end
end
