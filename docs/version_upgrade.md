# Performing version upgrades

## Elixir
An Elixir version upgrade may subsequently require a Phoenix version upgrade, which itself may require a Node upgrade.

It may be useful to copy the below checklist into your pull request description...

Places to update:
- [ ] .tool-versions - both Elixir and Erlang
- [ ] Dockerfile
  - Update the Elixir and Erlang versions in `FROM hexpm/elixir:X-erlang-Y-alpine-3.15.0 AS elixir-builder`. You may also need to use a newer Alpine Linux version. Search https://hub.docker.com/r/hexpm/elixir/tags for the appropriate image tag.
  - You may also need to install new OS packages to allow newer version of Erlang to run, e.g. `libstdc++` `libgcc` and `ncurses-libs` for Erlang/OTP 24+. Check with the team and/or department about these if you see errors about missing C libraries during build or bootup of the application. Add new required packages to the `RUN apk --update add ...` line. Available packages can be found at https://pkgs.alpinelinux.org/packages.
- [ ] .devcontainer/devcontainer.json - NOT .devcontainer/Dockerfile
- [ ] .credo.exs - remove disabled checks as appropriate
- [ ] mix.exs

After bumping the version and other relevant changes in these places, run `mix compile` and keep an eye on the console output.
Make changes appropriately to address any compile warnings/errors.
You may also need to bump mix dependency versions and navigate any breaking changes that come from those updates.

Check that tests pass: `mix test`

Check for any new credo complaints and address them as needed: `mix credo --strict`

Once everything looks good, start the server with `iex -S mix phx.server`. Thoroughly check that everything is looking as expected.

Test loading the following:
  - [ ] v1 screen (bus e-ink, GL e-ink single, GL e-ink double, solari, DUP)
  - [ ] v1 audio (solari)
  - [ ] v2 screen (bus e-ink, GL e-ink, bus shelter, pre-fare, others...?)
  - [ ] v2 audio (bus shelter, others...?)
  - [ ] admin

Create a PR with your changes and deploy to dev-green.
Point a bunch of browser tabs at various screen types on dev-green (get help from teammates!), and keep a close eye on splunk logs.
