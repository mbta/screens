defmodule Screens.FakeOidcc do
  @moduledoc false

  def client_credentials_token(:fake_issuer, "fake_client", "fake_client_secret", _opts) do
    {:ok,
     %Oidcc.Token{
       access: %Oidcc.Token.Access{
         token: "fake_access_token"
       }
     }}
  end
end
