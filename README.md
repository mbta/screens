# Screens

## Getting Started

1. Clone this repo
1. Install the [asdf package manager](https://github.com/asdf-vm/asdf)
1. Install dependencies:
   `brew install autoconf@2.69 coreutils gnupg`
1. Add `asdf` plugins:
   1. `asdf plugin-add erlang`
   1. `asdf plugin-add elixir`
   1. `asdf plugin-add nodejs`
1. Import the Node.js release team's OpenPGP keys to main keyring (this is required by asdf-nodejs):
   `bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring`
1. Install versions specified in `.tool-versions` with `asdf install`

   **If** you see an error along the lines of 
      ```sh
      configure: error: 

         You are natively building Erlang/OTP for a later version of MacOSX
         than current version (11.0). You either need to
         cross-build Erlang/OTP, or set the environment variable
         MACOSX_DEPLOYMENT_TARGET to 11.0 (or a lower version).
      ```
      you can try modifying the OTP source downloaded by `asdf` to get around it (More context can be found on [this Github issue](https://github.com/asdf-vm/asdf-erlang/issues/161#issuecomment-731477842)):

      ```sh
      cd ~/.asdf/plugins/erlang/kerl-home/archives
      tar zxvf OTP-<version>.tar.gz
      ```

      Next, modify **~/.asdf/plugins/erlang/kerl-home/archives/otp-OTP-{version}/make/configure.in** near line 415 by adding `&& false` (exact line # may vary based on OTP version):
      ```sh
      #if __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ > $int_macosx_version && false
      ```

      Re-tar the directory:
      ```sh
      tar cfz OTP-<version>.tar otp-OTP-<version>
      rm -rf otp-OTP-<version>
      ```
      Return to your screens repo and try running `asdf install` again.

1. Install Elixir dependencies with `mix deps.get`
1. Install Node.js dependencies with `npm install --prefix assets`
1. Get access to our S3 bucket from DevOps and/or a teammate and save the JSON found at mbta-ctd-config/screens/screens-prod.json as `priv/local.json` to supply your local server with config values. You will also need to grab the signs_ui_config JSON and save it at `priv/signs_ui_config.json`.
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

## Packaging the DUP app
The DUP screens require the client app to be packaged into a single HTML file rather than dynamically served from our Phoenix server.

You can find instructions on the packaging process [here](assets/src/components/dup/README.md).