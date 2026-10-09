# Getting Started

### Postgres

If you don't already have Postgres installed, and you're on a Mac, [Postgres.app](https://postgresapp.com/downloads.html) is an easy way to get started. However, any Postgres instance to which you can connect and in which you have sufficient privileges should work.

### Install tools

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

### Set up environment

1. Install [`direnv`](https://direnv.net/)
1. `cp .envrc.template .envrc`
1. Fill in `API_V3_KEY` with a [V3 API key](https://api-v3.mbta.com/)
   - If you haven't already, create a [V3 API account](https://api-v3.mbta.com/)
     using your work email, and use the portal to create an API key.
1. `direnv allow`

### AWS credentials

In deployed environments, the app writes and fetches snapshots of its 
configuration stored in S3 on regular cadences. These "latest" snapshots are 
how we sync configurations between environments. To access this functionality 
locally to pull screen configurations from a deployed environment, you'll need 
an AWS [access key](https://console.aws.amazon.com/iam/home#/security_credentials).

The app will use a key stored in the environment variables `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`. These can be exported or saved in a `.envrc` as
with the V3 API key above, but for security reasons it is recommended to only
[store them in 1Password][1]. There are a few ways to make these available to
the app using the 1Password CLI, but one way is using an export command like
this (which works in `.envrc`):

```sh
export AWS_SECRET_ACCESS_KEY=$(op item get --vault VAULT_NAME ITEM_NAME --field FIELD_NAME --reveal)
```

Remember to refresh your environment variables with `direnv allow` if storing in `.envrc`. 

### Start the server

1. `mix deps.get`
1. `npm install --prefix assets`
1. `mix ecto.create` to stand up the DB used for storing screen configs.
1. `mix phx.server` 
1. Visit <http://localhost:4000/admin> to verify that the application loads!

### Loading Screen Configurations into Postgres
1. Visit <http://localhost:4000/admin/tools>.
1. Within the section to "Sync Configurations from Source Environment", select 
an environment to sync from as a source. Starting with prod configurations is 
recommended, as these are guaranteed to be up-to-date and in expected working order.
1. Visit <http://localhost:4000/v2/screen/PRE-201> (one of our screens, chosen 
because North Station is cool) to check that everything is working!

[1]: https://www.notion.so/mbta-downtown-crossing/Storing-Access-Keys-Securely-in-1Password-b89310bc67784722a5a218500f34443d?pm=c
