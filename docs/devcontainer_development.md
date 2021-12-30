# Getting Started - Devcontainer Development

Some steps call for opening VS Code's "command palette"—you can do that with the shortcut <kbd>cmd</kbd>+<kbd>shift</kbd>+<kbd>P</kbd>.

## Access and keys
1. Get access to our S3 bucket from DevOps and/or a teammate and save the JSON found at mbta-ctd-config/screens/screens-prod.json as `priv/local.json` to supply your local server with screen configurations.
1. Visit [AWS security credentials](https://console.aws.amazon.com/iam/home#/security_credentials) and create an access key if you don't already have it. Keep the tab with this info open; you'll use it shortly.
1. Sign up for a [V3 API key](https://api-v3.mbta.com/). Keep the tab with this info open; you'll use it shortly.

## Environment setup
1. Install [Visual Studio Code](https://code.visualstudio.com/) and [Docker Desktop](https://www.docker.com/products/docker-desktop).
1. Clone this repo.
1. **Only if you are switching to Devcontainer development from previous local development,** clear out your Node modules before continuing (they need to be fetched/built anew within the container):
   ```sh
   rm -rf assets/{node_modules,package-lock.json}
   ```
1. From the project root, create the file `.devcontainer/devcontainer.env` to store environment variables needed by the app. At minimum, you will need these three lines:
   ```sh
   # Do not enclose the values in quotes!
   API_V3_KEY=abc123            # your MBTA V3 API key
   AWS_ACCESS_KEY_ID=qrs456     # your AWS access key
   AWS_SECRET_ACCESS_KEY=xyz789 # your AWS secret access key
   ```
1. Open the project directory in VS Code.
1. Install the [Remote-Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension: open the command palette, type "Install Extensions <kbd>return</kbd>", enter "Remote - Containers" in the search box of the pane that appears, and click "Install" on the first extension listed.
1. Start the dev container: open the command palette and type "Remote-Containers: Reopen in Container <kbd>return</kbd>". The build will start automatically and take a few minutes.
1. If the build succeeded, you should see `Done. Press any key to close the terminal.` in VS Code's console pane.
1. Open a new terminal tab in VS Code with the `+` button at the top right of the pane, or press <kbd>ctrl</kbd>+<kbd>\`</kbd>. Run `iex -S mix phx.server`. After a few seconds, VS Code should notify you that the server is reachable at port 4000. Visit [`localhost:4000/screen/1`](https://localhost:4000/screen/1) in your browser to check that everything is working. (You might need to wait for Webpack to finish bundling assets the first time.)

## Development
With the app now running in a container, you can begin development.

Edit project files in the container from VS Code, and the changes will automatically sync to your host OS's filesystem.

You can perform debug tasks and run an Elixir shell within the project's context from VS Code's terminal pane. The shell running `iex -S mix phx.server` is an Elixir REPL, against which you can call any public function defined in the project's code. You can open additional terminal tabs with the <kbd>+</kbd> button in the top right corner of the pane—these will launch a plain `zsh` shell.

If you ever need to restart the container, do so by opening the command palette and entering "Remote-Containers: Rebuild Container <kbd>return</kbd>" ("Without Cache" if you really want to do a clean rebuild).
