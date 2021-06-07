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
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:gettext, "~> 0.18.2"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:httpoison, "~> 1.8"},
      {:tzdata, "~> 1.1"},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14.1", only: :test},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.2"},
      {:ex_aws_secretsmanager, "~> 2.0", only: :prod},
      {:ex_aws_polly, "~> 0.4.0"},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:sweet_xml, "~> 0.6.6"},
      {:timex, "~> 3.7"},
      {:hackney, "~> 1.17"},
      {:guardian, "~> 2.1"},
      {:ueberauth, "~> 0.6.3"},
      {:ueberauth_cognito, "~> 0.2.0"},
      {:corsica, "~> 1.1"}
    ]
  end
end
