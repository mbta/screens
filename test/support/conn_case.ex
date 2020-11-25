defmodule ScreensWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ScreensWeb.ConnCase, async: true`, although
  this option is not recommendded for other databases.
  """

  use ExUnit.CaseTemplate
  import Plug.Test

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias ScreensWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint ScreensWeb.Endpoint
    end
  end

  setup tags do
    cond do
      tags[:authenticated] ->
        user = "test_user"

        screens_group = Application.get_env(:screens, :cognito_group)

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_req_header("x-forwarded-proto", "https")
          |> init_test_session(%{})
          |> Guardian.Plug.sign_in(ScreensWeb.AuthManager, user, %{groups: [screens_group]})

        {:ok, conn: conn}

      tags[:authenticated_not_in_group] ->
        user = "test_user"

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_req_header("x-forwarded-proto", "https")
          |> init_test_session(%{})
          |> Guardian.Plug.sign_in(ScreensWeb.AuthManager, user, %{groups: []})

        {:ok, conn: conn}

      true ->
        {:ok,
         conn:
           Phoenix.ConnTest.build_conn() |> Plug.Conn.put_req_header("x-forwarded-proto", "https")}
    end
  end
end
