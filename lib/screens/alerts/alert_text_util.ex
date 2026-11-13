defmodule Screens.Alerts.AlertTextUtil do
  @moduledoc """
  Text Util helper for getting alert text within AlertRows in Departures and ReconstructedAlerts
  """

  alias Screens.Alerts.Alert
  alias Screens.Alerts.KenmoreAlertHelper
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias ScreensConfig.FreeTextLine

  @spec end_time_text([Alert.active_period()], DateTime.t()) :: String.t() | nil
  def end_time_text([{_start_time, nil} | _], _now), do: nil

  def end_time_text([{_start_time, end_time} | _], now) do
    end_time_eastern = Util.to_eastern(end_time)
    end_date = Util.service_date(end_time)
    now_date = Util.service_date(now)

    cond do
      end_date == now_date and
        end_time_eastern.hour >= 2 and
          end_time_eastern.hour < 5 ->
        "end of service"

      end_date == now_date ->
        Calendar.strftime(end_time_eastern, "%-I:%M %p")

      Date.diff(end_date, now_date) == 1 ->
        "tomorrow"

      Date.beginning_of_week(end_date) == Date.beginning_of_week(now_date) ->
        "this #{Calendar.strftime(end_date, "%A")}"

      true ->
        Calendar.strftime(end_date, "%b %-d")
    end
  end

  @spec alert_row_text(NormalSection.AlertRow.t(), DateTime.t()) ::
          {FreeTextLine.t(), FreeTextLine.t()}
  def alert_row_text(
        %NormalSection.AlertRow{
          alert:
            %Alert{
              active_period: active_period,
              effect: effect,
              informed_entities: informed_entities
            } = alert,
          displayed_headsign: headsign,
          location: location,
          routes: [%Route{id: representative_route_id} = representative_route | _] = routes,
          home_stop: %Stop{id: stop_id}
        },
        now
      )
      when effect in [:shuttle, :suspension] do
    headsign_text =
      cond do
        # Kenmore special case, display the direction names for the affected branches
        KenmoreAlertHelper.kenmore_only_some_branches_affected?([alert], stop_id) ->
          KenmoreAlertHelper.get_branches_if_entity_matches_stop([alert])
          |> Enum.map_join(" and ", &KenmoreAlertHelper.branch_headsign(&1, false))

        # Multiple routes ala Green Line - combine them
        match?([_ | [_ | _]], routes) and match?("Green" <> _, representative_route_id) ->
          "Green Line"

        # Fallback to just using whatever headsign or route ID is first
        true ->
          if headsign do
            headsign
          else
            "#{representative_route.id} Line"
          end
      end

    header_text =
      %FreeTextLine{
        icon: nil,
        text:
          if location == :inside or location == :boundary_downstream do
            if effect == :shuttle do
              ["No #{headsign_text} service", %{special: :break}, "Use Shuttle Buses"]
            else
              ["No #{headsign_text} trains"]
            end
          else
            [headsign]
          end
      }

    {effect_text, extra_text} =
      case effect do
        :shuttle ->
          {%{format: "bold", text: "Shuttle buses"}, ""}

        :suspension ->
          {%{format: "bold", text: "Service suspended"}, "Plan a new trip at mbta.com/alerts."}
      end

    {{min_full_name, _min_abbr_name}, {max_full_name, _max_abbr_name}} =
      Screens.Alerts.Endpoints.get_endpoints(
        informed_entities,
        if match?("Green" <> _, representative_route_id) do
          "Green"
        else
          representative_route_id
        end
      )

    endpoint_text = [
      "from",
      %{format: "bold", text: min_full_name},
      "to",
      %{format: "bold", text: max_full_name}
    ]

    end_time = end_time_text(active_period, now)

    end_time_text =
      if is_nil(end_time) do
        [""]
      else
        ["through", "#{end_time}."]
      end

    additional_text = %FreeTextLine{
      icon: nil,
      text: [effect_text] ++ endpoint_text ++ end_time_text ++ [extra_text]
    }

    {header_text, additional_text}
  end

  def alert_row_text(
        %NormalSection.AlertRow{
          alert: %Alert{effect: effect, header: header},
          displayed_headsign: headsign,
          location: location,
          home_stop: %Stop{name: name}
        },
        _now
      )
      when effect in [:station_closure, :stop_closure] do
    vehicle =
      if effect == :station_closure do
        "Trains"
      else
        "Buses"
      end

    header_text =
      %FreeTextLine{
        icon: nil,
        text:
          if location == :inside do
            ["#{vehicle} skip #{name}"]
          else
            [headsign]
          end
      }

    additional_text = %FreeTextLine{
      icon: nil,
      text: [header]
    }

    {header_text, additional_text}
  end

  def alert_row_text(
        %NormalSection.AlertRow{
          alert: %Alert{effect: effect, header: header},
          displayed_headsign: headsign,
          location: location
        },
        _now
      )
      when effect in [:stop_move, :stop_moved] do
    header_text =
      %FreeTextLine{
        icon: nil,
        text:
          if location == :inside do
            ["Stop Moved"]
          else
            [headsign]
          end
      }

    additional_text = %FreeTextLine{
      icon: nil,
      text: [header]
    }

    {header_text, additional_text}
  end
end
