# Screens

This application serves real-time information to all of our browser-based screens posted at stops and stations around the system.

If you're looking for the application that controls the LED countdown clocks and the in-station PA system, please see [mbta/realtime_signs](https://github.com/mbta/realtime_signs).

Some examples of the various client apps, as of January 2023:

| screen type (click for a sample screenshot) | description |
| - | - |
| [Bus E-Ink][bus_eink sample] | solar-powered E-Ink screens at bus stops |
| [Green Line E-Ink][gl_eink sample] | solar-powered E-Ink screens at surface-level Green Line stops |
| [Bus corridor LCD][bus_shelter sample] | currently used at stops on the Columbus Ave bus corridor |
| [Multimodal LCD][solari sample] | used at high-traffic transfer stations served by many routes/modes |
| [Pre-fare duo LCD][pre_fare sample] | posted outside of fare gates at rapid transit stations |
| ["Digital Urban Panel" LCD][dup sample] | content appears in rotation with ads on screens posted outside rapid transit station entrances |

and more to come!

## Getting Started
You have two options to set up the project environment for development:
1. [Run on your local machine, with dependencies installed locally.](docs/local_development.md)
   - Pros: Runs fast; use the code editor of your choice
   - Cons: Requires building Erlang from source; makes version upgrades more difficult
1. :new::sparkles: [Run inside a Docker container using VS Code's Devcontainer extension.](docs/devcontainer_development.md)
   - Pros: Simple, one-click build process; easy version upgrades; integrated-ish development environment; host-OS-agnostic
   - Cons: Restricted to VS Code as an editor; file read/write is a bit slower

## Architecture
On <sup>almost</sup> all of our screen types, we use a common "framework" to fetch relevant real-time info for the screen's location, and then determine which pieces of info are most important to riders from moment to moment.

Check out [ARCHITECTURE.md](/ARCHITECTURE.md) for an overview of the application architecture, as well as links to further more detailed documentation.

## Packaging the DUP app
The DUP screens require the client app to be packaged into a single HTML file rather than dynamically served from our Phoenix server.

You can find instructions on the packaging process [here](assets/src/components/dup/README.md).

## Version upgrade guide
You can find some hopefully useful notes on upgrading the project's Elixir version, and possibly other upgrades, [here](docs/version_upgrade.md).

[bus_eink sample]: /docs/assets/sample_app_screenshots/bus_eink.png
[gl_eink sample]: /docs/assets/sample_app_screenshots/gl_eink.png
[bus_shelter sample]: /docs/assets/sample_app_screenshots/bus_shelter.png
[solari sample]: /docs/assets/sample_app_screenshots/solari.png
[pre_fare sample]: /docs/assets/sample_app_screenshots/pre_fare.png
[dup sample]: /docs/assets/sample_app_screenshots/dup.png
