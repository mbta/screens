defmodule Screens.DupScreenData do
  @moduledoc false

  alias Screens.Config.{Dup, State}
  alias Screens.Config.Dup.Override.{FullscreenAlert, FullscreenImage, PartialAlertList}
  alias Screens.DupScreenData.{Data, Request, Response}

  def by_screen_id(screen_id, rotation_index)

  def by_screen_id(screen_id, rotation_index) when rotation_index in ~w[0 1] do
    %Dup{primary: primary_departures, override: override} = State.app_params(screen_id)
    disabled = State.disabled?(screen_id)

    case {override, rotation_index, disabled} do
      {_, _, true} ->
        disabled_response()

      {nil, _, _} ->
        primary_screen_response(primary_departures, rotation_index)

      {{screen0, _}, "0", _} ->
        primary_screen_response_with_override(primary_departures, rotation_index, screen0)

      {{_, screen1}, "1", _} ->
        primary_screen_response_with_override(primary_departures, rotation_index, screen1)
    end
  end

  def by_screen_id(screen_id, "2") do
    %Dup{secondary: secondary_departures} = State.app_params(screen_id)

    case secondary_departures do
      %Dup.Departures{sections: []} ->
        by_screen_id(screen_id, "0")

      _ ->
        current_time = DateTime.utc_now()
        fetch_departures_response(secondary_departures, current_time)
    end
  end

  defp disabled_response do
    current_time = DateTime.utc_now()

    %{
      force_reload: false,
      success: true,
      type: :disabled,
      current_time: Screens.Util.format_time(current_time)
    }
  end

  defp primary_screen_response(primary_departures, rotation_index) do
    alerts = fetch_and_interpret_alerts(primary_departures)

    line_count = Data.station_line_count(primary_departures)

    current_time = DateTime.utc_now()

    case Data.response_type(alerts, line_count, rotation_index) do
      :departures ->
        fetch_departures_response(primary_departures, current_time)

      :partial_alert ->
        fetch_partial_alert_response(primary_departures, alerts, current_time)

      :fullscreen_alert ->
        fetch_fullscreen_alert_response(primary_departures, alerts, line_count)
    end
  end

  defp primary_screen_response_with_override(
         primary_departures,
         rotation_index,
         %PartialAlertList{} = override
       ) do
    alerts = fetch_and_interpret_alerts(primary_departures)

    line_count = Data.station_line_count(primary_departures)

    current_time = DateTime.utc_now()

    case Data.response_type(alerts, line_count, rotation_index) do
      :fullscreen_alert ->
        fetch_fullscreen_alert_response(primary_departures, alerts, line_count)

      _ ->
        fetch_partial_alert_response(primary_departures, override, current_time, override: true)
    end
  end

  defp primary_screen_response_with_override(primary_departures, _, %FullscreenAlert{} = override) do
    alert_response = FullscreenAlert.to_json(override)

    Map.merge(
      alert_response,
      %{
        type: :full_screen_alert,
        force_reload: false,
        success: true,
        header: alert_response.header || primary_departures.header
      }
    )
  end

  defp primary_screen_response_with_override(
         _primary_departures,
         _,
         %FullscreenImage{image_url: image_url}
       ) do
    current_time = DateTime.utc_now()

    %{
      force_reload: false,
      success: true,
      type: :static_image,
      image_url: image_url,
      current_time: Screens.Util.format_time(current_time)
    }
  end

  defp fetch_and_interpret_alerts(%Dup.Departures{sections: sections}) do
    sections
    |> Task.async_stream(&fetch_and_interpret_alert/1)
    |> Enum.flat_map(fn {:ok, data} -> data end)
  end

  defp fetch_and_interpret_alert(%Dup.Section{
         stop_ids: stop_ids,
         route_ids: route_ids,
         pill: pill
       })
       when pill in ~w[red orange green blue]a do
    alerts = Request.fetch_alerts(stop_ids, route_ids)

    alerts
    |> Data.choose_alert()
    |> case do
      nil -> []
      alert -> [Data.interpret_alert(alert, stop_ids, pill)]
    end
  end

  defp fetch_and_interpret_alert(_non_subway_section), do: []

  defp fetch_departures_response(
         %Dup.Departures{header: header, sections: sections},
         current_time
       ) do
    sections_data = Request.fetch_sections_data(sections, current_time)

    case sections_data do
      {:ok, data} ->
        %{
          force_reload: false,
          success: true,
          header: header,
          sections: data,
          current_time: Screens.Util.format_time(current_time),
          type: :departures
        }

      :error ->
        %{force_reload: false, success: false}
    end
  end

  defp fetch_partial_alert_response(primary_departures, alerts, current_time, opts \\ []) do
    departures_response = fetch_departures_response(primary_departures, current_time)

    case departures_response do
      %{force_reload: false, success: true, sections: sections} ->
        alerts =
          if(Keyword.get(opts, :override, false),
            do: PartialAlertList.to_json(alerts).alerts,
            else: Response.render_partial_alerts(alerts)
          )

        Map.merge(
          departures_response,
          %{
            sections: Data.limit_three_departures(sections),
            alerts: alerts
          }
        )

      _ ->
        departures_response
    end
  end

  defp fetch_fullscreen_alert_response(%Dup.Departures{header: header}, [alert], line_count) do
    %{
      type: :full_screen_alert,
      force_reload: false,
      success: true,
      header: header,
      pattern: Response.pattern(alert.region, alert.effect, line_count),
      color: Response.color(alert.pill, alert.effect, line_count, 1),
      issue: Response.alert_issue(alert),
      remedy: Response.alert_remedy(alert)
    }
  end

  defp fetch_fullscreen_alert_response(%Dup.Departures{header: header}, [alert, _alert], _) do
    %{
      type: :full_screen_alert,
      force_reload: false,
      success: true,
      header: header,
      pattern: :x,
      color: :yellow,
      issue: Response.alert_issue(alert),
      remedy: Response.alert_remedy(alert)
    }
  end
end
