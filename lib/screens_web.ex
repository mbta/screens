defmodule ScreensWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ScreensWeb, :controller
      use ScreensWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(css fonts images js favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: ScreensWeb,
        layouts: [html: {ScreensWeb.LayoutView, :app}]

      import Plug.Conn
      use Gettext, backend: ScreensWeb.Gettext
      alias ScreensWeb.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/screens_web/templates",
        namespace: ScreensWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML, except: [sigil_E: 2]
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      import ScreensWeb.HTML

      import ScreensWeb.ErrorHelpers
      use Gettext, backend: ScreensWeb.Gettext
      alias ScreensWeb.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: ScreensWeb.Gettext
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ScreensWeb.Endpoint,
        router: ScreensWeb.Router,
        statics: ScreensWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
