defmodule Screens.V2.WebLink do
  @moduledoc """
    Utility module for creating links for Alerts and Elevator Status
  """

  def route_alert_url_app(alert_id, route_id) do
    "go.mbta.com/a/#{alert_id}/r/#{route_id}"
  end

  def stop_alert_url_app(alert_id, stop_id) do
    "go.mbta.com/a/#{alert_id}/s/#{stop_id}"
  end

  def stop_url_app(stop_id), do: "go.mbta.com/s/#{stop_id}"
  def stop_url_web(stop_id), do: "mbta.com/stops/#{stop_id}"

  def alternate_route_url(vanity_url) when is_nil(vanity_url) or vanity_url == "" do
    "mbta.com/alerts"
  end

  def alternate_route_url(vanity_url) do
    vanity_url
    |> String.replace(~r/^https?:\/\//i, "")
    |> String.replace(~r/^www\./i, "")
  end
end
