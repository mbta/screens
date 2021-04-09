defmodule Screens.DupScreenData.SpecialCases do
  @moduledoc false

  alias Screens.Config.Dup

  alias Screens.Config.Dup.Override.{
    FreeTextLine,
    PartialAlert,
    PartialAlertList
  }

  alias Screens.DupScreenData.{Data, Request}

  def handle_special_cases(
        %Dup.Departures{
          sections: [
            %Dup.Section{
              stop_ids: ["place-kencl"] = stop_ids,
              route_ids: ["Green-B", "Green-C", "Green-D"] = route_ids,
              pill: pill
            }
          ]
        } = primary_departures,
        rotation_index
      ) do
    alerts = Request.fetch_alerts(stop_ids, route_ids)

    interpreted_alerts =
      alerts
      |> Enum.map(fn alert ->
        alert
        |> Data.interpret_alert(stop_ids, pill)
        |> Map.put(:routes, Data.alert_routes_at_station(alert, stop_ids))
      end)
      |> Enum.sort_by(& &1.routes)

    render_kenmore_alerts(interpreted_alerts, primary_departures, rotation_index)
  end

  def handle_special_cases(_, _), do: nil

  defp render_kenmore_alerts(interpreted_alerts, primary_departures, "0") do
    current_time = DateTime.utc_now()

    case kenmore_partial_alert_text(interpreted_alerts) do
      {:ok, text} ->
        line = %FreeTextLine{icon: :warning, text: text}
        override = %PartialAlertList{alerts: [%PartialAlert{color: :green, content: line}]}

        {:ok,
         Screens.DupScreenData.fetch_partial_alert_response(
           primary_departures,
           override,
           current_time,
           override: true
         )}

      {:ok, text, headway_message} ->
        render_kenmore_headway_alert(text, headway_message)

      _ ->
        nil
    end
  end

  defp render_kenmore_alerts(interpreted_alerts, _primary_departures, "1") do
    case kenmore_fullscreen_alert_text(interpreted_alerts) do
      nil ->
        nil

      issue_text ->
        issue = %{
          icon: :warning,
          text: issue_text
        }

        remedy = %{
          icon: :shuttle,
          text: [%{format: :bold, text: "Use shuttle bus"}]
        }

        response = %{
          type: :full_screen_alert,
          force_reload: false,
          success: true,
          header: "Kenmore",
          pattern: :x,
          color: :green,
          issue: issue,
          remedy: remedy
        }

        {:ok, response}
    end
  end

  defp render_kenmore_headway_alert(text, headway_message) do
    current_time = DateTime.utc_now()
    line = %FreeTextLine{icon: :warning, text: text}
    override = %PartialAlertList{alerts: [%PartialAlert{color: :green, content: line}]}

    response = %{
      force_reload: false,
      success: true,
      header: "Kenmore",
      sections: [%{headway: headway_message}],
      alerts: PartialAlertList.to_json(override).alerts,
      current_time: Screens.Util.format_time(current_time),
      type: :departures
    }

    {:ok, response}
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, routes: ["Green-B"], headsign: "Boston College"},
         %{effect: :shuttle, region: :boundary, routes: ["Green-C"], headsign: "Cleveland Circle"}
       ]) do
    kenmore_bc_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: "BC/Clev. Circ."}
       ]) do
    kenmore_bc_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, routes: ["Green-B"], headsign: "Boston College"},
         %{effect: :shuttle, region: :boundary, routes: ["Green-D"], headsign: "Riverside"}
       ]) do
    kenmore_bd_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: "BC/Riverside"}
       ]) do
    kenmore_bd_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{
           effect: :shuttle,
           region: :boundary,
           routes: ["Green-C"],
           headsign: "Cleveland Circle"
         },
         %{
           effect: :shuttle,
           region: :boundary,
           routes: ["Green-D"],
           headsign: "Riverside"
         }
       ]) do
    kenmore_cd_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: "Clev. Circ./Riverside"}
       ]) do
    kenmore_cd_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, routes: ["Green-B"], headsign: "Boston College"},
         %{
           effect: :shuttle,
           region: :boundary,
           routes: ["Green-C"],
           headsign: "Cleveland Circle"
         },
         %{effect: :shuttle, region: :boundary, routes: ["Green-D"], headsign: "Riverside"}
       ]) do
    kenmore_bcd_partial_alert_text()
  end

  defp kenmore_partial_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: {:adj, "westbound"}}
       ]) do
    kenmore_bcd_partial_alert_text()
  end

  defp kenmore_partial_alert_text(_), do: nil

  defp kenmore_bc_partial_alert_text do
    {:ok, ["No", %{format: :bold, text: "Bost Coll/Clvlnd Cir"}]}
  end

  defp kenmore_bd_partial_alert_text do
    {:ok, ["No", %{format: :bold, text: "Bost Coll / Riverside"}]}
  end

  defp kenmore_cd_partial_alert_text do
    {:ok, ["No", %{format: :bold, text: "Clvlnd Cir/Riverside"}]}
  end

  defp kenmore_bcd_partial_alert_text do
    partial_alert_text = ["No", %{format: :bold, text: "Westbound"}, "trains"]

    kenmore_headway_id = "green_trunk"
    time_ranges = Screens.SignsUiConfig.State.time_ranges(kenmore_headway_id)
    current_time_period = DateTime.utc_now() |> Screens.Util.time_period()

    case time_ranges do
      %{^current_time_period => {lo, hi}} ->
        headway_message = %{
          icon: "subway-negative-black",
          text: [
            %{color: :green, text: "GREEN LINE"},
            %{special: :break},
            "every",
            %{format: :bold, text: "#{lo}-#{hi}"},
            "minutes"
          ]
        }

        {:ok, partial_alert_text, headway_message}

      _ ->
        {:ok, partial_alert_text}
    end
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, routes: ["Green-B"], headsign: "Boston College"},
         %{effect: :shuttle, region: :boundary, routes: ["Green-C"], headsign: "Cleveland Circle"}
       ]) do
    kenmore_bc_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: "BC/Clev. Circ."}
       ]) do
    kenmore_bc_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, routes: ["Green-B"], headsign: "Boston College"},
         %{effect: :shuttle, region: :boundary, routes: ["Green-D"], headsign: "Riverside"}
       ]) do
    kenmore_bd_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: "BC/Riverside"}
       ]) do
    kenmore_bd_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{
           effect: :shuttle,
           region: :boundary,
           routes: ["Green-C"],
           headsign: "Cleveland Circle"
         },
         %{effect: :shuttle, region: :boundary, routes: ["Green-D"], headsign: "Riverside"}
       ]) do
    kenmore_cd_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: "Clev. Circ./Riverside"}
       ]) do
    kenmore_cd_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, routes: ["Green-B"], headsign: "Boston College"},
         %{
           effect: :shuttle,
           region: :boundary,
           routes: ["Green-C"],
           headsign: "Cleveland Circle"
         },
         %{effect: :shuttle, region: :boundary, routes: ["Green-D"], headsign: "Riverside"}
       ]) do
    kenmore_bcd_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text([
         %{effect: :shuttle, region: :boundary, headsign: {:adj, "westbound"}}
       ]) do
    kenmore_bcd_fullscreen_alert_text()
  end

  defp kenmore_fullscreen_alert_text(_), do: nil

  defp kenmore_bc_fullscreen_alert_text do
    [
      "No",
      %{icon: :green_b},
      %{format: :bold, text: "Boston Coll"},
      "or",
      %{special: :break},
      %{icon: :green_c},
      %{format: :bold, text: "Cleveland Cir"},
      "trains"
    ]
  end

  defp kenmore_bd_fullscreen_alert_text do
    [
      "No",
      %{icon: :green_b},
      %{format: :bold, text: "Boston College"},
      "or",
      %{special: :break},
      %{icon: :green_d},
      %{format: :bold, text: "Riverside"},
      "trains"
    ]
  end

  defp kenmore_cd_fullscreen_alert_text do
    [
      "No",
      %{icon: :green_c},
      %{format: :bold, text: "Cleveland Cir"},
      "or",
      %{special: :break},
      %{icon: :green_d},
      %{format: :bold, text: "Riverside"},
      "trains"
    ]
  end

  defp kenmore_bcd_fullscreen_alert_text do
    [
      "No",
      %{icon: :green_b},
      %{icon: :green_c},
      %{icon: :green_d},
      %{format: :bold, text: "Westbound"},
      "trains"
    ]
  end
end
