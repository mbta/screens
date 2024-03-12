# Getting Started

1. Clone this repo
1. Install [`asdf`](https://github.com/asdf-vm/asdf)
1. Install language build dependencies: `brew install coreutils`
1. Add `asdf` plugins:
   1. `asdf plugin-add erlang`
   1. `asdf plugin-add elixir`
   1. `asdf plugin-add nodejs`
1. Install versions specified in `.tool-versions` with `asdf install`
1. Install Elixir dependencies with `mix deps.get`
1. Install Node.js dependencies with `npm install --prefix assets`
1. Run `scripts/pull_configs.sh dev`. This will save the current Screens and
   Signs-UI configuration stored on S3 to the `priv` directory, which is where
   the app expects to find this configuration when running locally.
   * This script uses the `aws` CLI, so it assumes you have this installed and
     configured with working credentials, and that your AWS account has Screens
     team permissions. If you don't have all this completely set up but do have
     S3 access through the AWS web console, you can get the files from there,
     referring to the script to see what to copy and where to save it. Or, ask
     the team if someone can send you their files!
1. If you haven't already, create a [V3 API account](https://api-v3.mbta.com/)
   using your work email, and use the portal to create an API key.
1. Start the Phoenix server with `env API_V3_KEY="your-key" mix phx.server`.
1. Visit <http://localhost:4000/v2/screen/PRE-101> (one of our screens, chosen
   arbitrarily) to check that everything is working!

### Environment variables

To avoid having to paste your V3 API key into the terminal every time you want
to start the server, you can add it to your environment. The `export` command
does this for the rest of the shell session it's run in:

```sh
export API_V3_KEY="your-key-here"
```

[`direnv`](https://direnv.net/) is a convenient way to load exports like this
automatically on a per-project basis. Once installed, you can create a `.envrc`
file in the root of this (or any) project, with the above as its content; when
your current directory is in the project, the variable will be loaded. Keep in
mind any changes to this file must be followed by a `direnv allow` to approve
them.

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
