# Performing version upgrades

## Elixir
An Elixir version upgrade may subsequently require a Phoenix version upgrade, which itself may require a Node upgrade.

It may be useful to copy the below checklist into your pull request description...

Places to update:
- [ ] .tool-versions (both Elixir and Erlang)
- [ ] Dockerfile
- [ ] .devcontainer/devcontainer.json (NOT .devcontainer/Dockerfile)
- [ ] .credo.exs (remove disabled checks as appropriate)
- [ ] mix.exs
- [ ] 
