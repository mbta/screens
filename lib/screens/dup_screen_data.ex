defmodule Screens.DupScreenData do
  @moduledoc false

  alias Screens.Config.{Dup, State}

  alias Screens.Config.Dup.Override.{
    FullscreenAlert,
    FullscreenImage,
    PartialAlertList
  }

  alias Screens.DupScreenData.{Data, Request, Response, SpecialCases}

  def by_screen_id(screen_id, rotation_index, now \\ DateTime.utc_now())

  def by_screen_id(screen_id, rotation_index, now) when rotation_index in ~w[0 1] do
    %Dup{primary: primary_departures, override: override} = State.app_params(screen_id)
    disabled = State.disabled?(screen_id)

    case {override, rotation_index, disabled} do
      {_, _, true} ->
        disabled_response(now)

      {{screen0, _, _}, "0", _} when not is_nil(screen0) ->
        primary_screen_response_with_override(primary_departures, rotation_index, screen0, now)

      {{_, screen1, _}, "1", _} when not is_nil(screen1) ->
        primary_screen_response_with_override(primary_departures, rotation_index, screen1, now)

      {_, _, _} ->
        primary_screen_response(primary_departures, rotation_index, now)
    end
  end

  def by_screen_id(screen_id, "2", now) do
    %Dup{secondary: secondary_departures, override: override} = State.app_params(screen_id)

    case {secondary_departures, override} do
      {%Dup.Departures{sections: []}, _} ->
        by_screen_id(screen_id, "0")

      {_, {_, _, screen2}} ->
        fetch_partial_alert_response(secondary_departures, screen2, now, override: true)

      {_, _} ->
        fetch_departures_response(secondary_departures, %{}, now)
    end
  end

  defp disabled_response(current_time) do
    %{
      force_reload: false,
      success: true,
      type: :disabled,
      current_time: Screens.Util.format_time(current_time)
    }
  end

  defp primary_screen_response(primary_departures, rotation_index, current_time) do
    case SpecialCases.handle_special_cases(primary_departures, rotation_index, current_time) do
      {:ok, response} ->
        response

      nil ->
        default_primary_screen_response(primary_departures, rotation_index, current_time)
    end
  end

  defp default_primary_screen_response(primary_departures, rotation_index, current_time) do
    alerts_by_section = fetch_and_interpret_alerts(primary_departures)
    alerts = flatten_alerts(alerts_by_section)

    line_count = Data.station_line_count(primary_departures)

    case Data.response_type(alerts, line_count, rotation_index) do
      :departures ->
        fetch_departures_response(primary_departures, alerts_by_section, current_time)

      :partial_alert ->
        fetch_partial_alert_response(primary_departures, alerts_by_section, current_time)

      :fullscreen_alert ->
        fetch_fullscreen_alert_response(primary_departures, alerts, line_count)
    end
  end

  defp primary_screen_response_with_override(
         primary_departures,
         rotation_index,
         %PartialAlertList{} = override,
         current_time
       ) do
    alerts_by_section = fetch_and_interpret_alerts(primary_departures)
    alerts = flatten_alerts(alerts_by_section)

    line_count = Data.station_line_count(primary_departures)

    case Data.response_type(alerts, line_count, rotation_index) do
      :fullscreen_alert ->
        fetch_fullscreen_alert_response(primary_departures, alerts, line_count)

      _ ->
        fetch_partial_alert_response(primary_departures, override, current_time, override: true)
    end
  end

  defp primary_screen_response_with_override(
         primary_departures,
         _,
         %FullscreenAlert{} = override,
         _current_time
       ) do
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
         %FullscreenImage{image_url: image_url},
         current_time
       ) do
    %{
      force_reload: false,
      success: true,
      type: :static_image,
      image_url: image_url,
      current_time: Screens.Util.format_time(current_time)
    }
  end

  defp flatten_alerts(alerts_by_section) do
    Enum.flat_map(alerts_by_section, fn {_pill, alerts} -> alerts end)
  end

  defp fetch_and_interpret_alerts(%Dup.Departures{sections: sections}) do
    sections
    |> Task.async_stream(&fetch_and_interpret_alert/1, timeout: :infinity)
    |> Enum.map(fn {:ok, data} -> data end)
    |> Enum.into(%{})
  end

  defp fetch_and_interpret_alert(%Dup.Section{
         stop_ids: stop_ids,
         route_ids: route_ids,
         pill: pill
       })
       when pill in ~w[red orange green blue]a do
    alerts = Request.fetch_alerts(stop_ids, route_ids)

    chosen_alert =
      alerts
      |> Data.choose_alert()
      |> case do
        nil -> []
        alert -> [Data.interpret_alert(alert, stop_ids, pill)]
      end

    {pill, chosen_alert}
  end

  defp fetch_and_interpret_alert(%Dup.Section{pill: pill}), do: {pill, []}

  defp fetch_departures_response(
         %Dup.Departures{header: header, sections: sections},
         alerts_by_section,
         current_time
       ) do
    sections_with_alerts =
      Enum.map(sections, fn section ->
        {section, Map.get(alerts_by_section, section.pill)}
      end)

    sections_data = Request.fetch_sections_data(sections_with_alerts, current_time)

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

  def fetch_partial_alert_response(
        primary_departures,
        alerts_or_override,
        current_time,
        opts \\ []
      ) do
    override? = Keyword.get(opts, :override, false)
    alerts_by_section = if(override?, do: %{}, else: alerts_or_override)
    alerts = if(override?, do: alerts_or_override, else: flatten_alerts(alerts_by_section))

    departures_response =
      fetch_departures_response(primary_departures, alerts_by_section, current_time)

    case departures_response do
      %{force_reload: false, success: true, sections: sections} ->
        alerts =
          if(override?,
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
      issue: Response.alert_issue(alert, line_count),
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
      issue: Response.alert_issue(alert, 2),
      remedy: Response.alert_remedy(alert)
    }
  end
end
