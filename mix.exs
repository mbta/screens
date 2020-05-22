defmodule Screens.MixProject do
  use Mix.Project

  def project do
    [
      app: :screens,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :transitive,
        flags: [
          :race_conditions,
          :unmatched_returns
        ]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    apps = [:logger, :runtime_tools]

    apps =
      if Mix.env() == :prod do
        [:ehmon | apps]
      else
        apps
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
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:httpoison, "~> 1.6"},
      {:tzdata, "~> 1.0.3"},
      {:credo, "~> 1.4.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.12.3", only: :test},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_secretsmanager, "~> 2.0", only: :prod},
      {:ex_aws_polly, "~> 0.3.1"},
      {:poison, "~> 3.0"},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:sweet_xml, "~> 0.6.6"},
      {:timex, "~> 3.6"}
    ]
  end
end
