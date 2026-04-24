defmodule ScreensWeb.Plug.VariantCanary do
  @moduledoc """
  Randomizes a percentage of "real screen" data requests that do not specify a variant to instead
  use a specific variant under testing. Expects to be run after `ScreenRequest` in the pipeline.
  """

  alias Plug.Conn
  alias ScreensConfig.Screen

  @app_id :dup_v2
  @is_enabled Mix.env() != :test
  @percentage 1
  @variant "new_departures"

  def init(options), do: options

  def call(
        %Conn{assigns: %{is_real_screen: true, screen: %Screen{app_id: @app_id}, variant: nil}} =
          conn,
        _options
      ) do
    if @is_enabled and :rand.uniform() * 100 < @percentage do
      # Update metadata previously set in `ScreenRequest` so request logging remains accurate
      Logger.metadata(variant: @variant)
      Conn.assign(conn, :variant, @variant)
    else
      conn
    end
  end

  def call(conn, _options), do: conn
end
