## Getting Started - Local Development

1. Clone this repo
1. Install the [asdf package manager](https://github.com/asdf-vm/asdf)
1. Install dependencies:
   `brew install autoconf coreutils gnupg`
1. Add `asdf` plugins:
   1. `asdf plugin-add erlang`
   1. `asdf plugin-add elixir`
   1. `asdf plugin-add nodejs`
1. Import the Node.js release team's OpenPGP keys to main keyring (this is required by asdf-nodejs):
   `bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring`
1. Install versions specified in `.tool-versions` with `asdf install`
1. Install Elixir dependencies with `mix deps.get`
1. Install Node.js dependencies with `npm install --prefix assets`
1. Get access to our S3 bucket from DevOps and/or a teammate and save the JSON found at mbta-ctd-config/screens/screens-prod.json as `priv/local.json` to supply your local server with config values.
1. Visit [AWS security credentials](https://console.aws.amazon.com/iam/home#/security_credentials) and create an access key if you don't already have it. Save the access key ID and secret access key as environment variables:

   ```sh
   export AWS_ACCESS_KEY_ID="<key id>"
   export AWS_SECRET_ACCESS_KEY="<secret key>"
   ```

   You can put this in `priv/local.env` if you like, and it will be ignored by git. Wherever you put the keys, make sure to `source` them before running the local server.

1. Sign up for a [V3 API key](https://api-v3.mbta.com/)
1. Start Phoenix endpoint with `API_V3_KEY=<your-key-here> mix phx.server`

Visit [`localhost:4000/screen/1`](http://localhost:4000/screen/1) in your browser to check that everything is working.

You may want to add `export API_V3_KEY=<your-key-here>` to your shell config so that you don't have to specify it each time you run `mix phx.server`.
