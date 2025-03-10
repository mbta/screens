# Getting Started

#### Install tools

1. Clone this repo
1. Install [`asdf`](https://github.com/asdf-vm/asdf)
1. Install language build dependencies: `brew install coreutils`
1. Add `asdf` plugins:
   ```bash
   asdf plugin add erlang
   asdf plugin add elixir
   asdf plugin add nodejs
   ```
1. Install versions specified in `.tool-versions` with `asdf install`

#### Set up environment

1. Install [`direnv`](https://direnv.net/)
1. `cp .envrc.template .envrc`
1. Fill in `API_V3_KEY` with a [V3 API key](https://api-v3.mbta.com/)
   - If you haven't already, create a [V3 API account](https://api-v3.mbta.com/)
     using your work email, and use the portal to create an API key.
1. `direnv allow`

#### Copy configuration

1. Run `scripts/pull_configs.sh dev`. This will save the current Screens and
   Signs-UI configuration stored on S3 to the `priv` directory, which is where
   the app expects to find this configuration when running locally.
   - This script uses the `aws` CLI, so it assumes you have this installed and
     configured with working credentials, and that your AWS account has Screens
     team permissions.
   - Once you have the CLI installed, go to the console and then go to your
     account and select "Security Credentials". Under "Access Keys" select
     "Create access key" if you don't have one already. Use the access key id
     and secret access key to auth in the CLI with the `aws configure` command.

#### Start the server

1. `mix deps.get`
1. `npm install --prefix assets`
1. `mix phx.server`
1. Visit <http://localhost:4000/v2/screen/PRE-101> (one of our screens, chosen
   arbitrarily) to check that everything is working!

### AWS credentials

In deployed environments, the app gets its configuration directly from S3, and
the admin interface can write the configuration to S3 as well. To test or work
on this functionality locally, you'll need an AWS
[access key](https://console.aws.amazon.com/iam/home#/security_credentials).

The app will use a key stored in the environment variables `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`. These can be exported or saved in a `.envrc` as
with the V3 API key above, but for security reasons it is recommended to only
[store them in 1Password][1]. There are a few ways to make these available to
the app using the 1Password CLI, but one way is using an export command like
this (which works in `.envrc`):

```sh
export AWS_SECRET_ACCESS_KEY=$(op item get --vault VAULT_NAME ITEM_NAME --field FIELD_NAME)
```

[1]: https://www.notion.so/mbta-downtown-crossing/Storing-Access-Keys-Securely-in-1Password-b89310bc67784722a5a218500f34443d?pm=c
