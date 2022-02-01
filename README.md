# Screens

## Getting Started
You have two options to set up the project environment for development:
1. [Run on your local machine, with dependencies installed locally.](docs/local_development.md)
   - Pros: Runs fast; use the code editor of your choice
   - Cons: Requires building Erlang from source; makes version upgrades more difficult
1. :new::sparkles: [Run inside a Docker container using VS Code's Devcontainer extension.](docs/devcontainer_development.md)
   - Pros: Simple, one-click build process; easy version upgrades; integrated-ish development environment; host-OS-agnostic
   - Cons: Restricted to VS Code as an editor; file read/write is a bit slower

## Packaging the DUP app
The DUP screens require the client app to be packaged into a single HTML file rather than dynamically served from our Phoenix server.

You can find instructions on the packaging process [here](assets/src/components/dup/README.md).

## Version upgrade guide
You can find some hopefully useful notes on upgrading the project's Elixir version, and possibly other upgrades, [here](docs/version_upgrade.md).
