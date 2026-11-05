defmodule Screens.Alerts.AlertTextUtil do
  @moduledoc """
  Text Util helper for getting alert text within AlertRows in Departures and ReconstructedAlerts
  """

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.Departures.NormalSection.AlertRow
  alias Screens.Util
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

  @spec alert_row_text(NormalSection.AlertRow.t(), [Route.t()], String.t(), :inside | :downstream)
  def alert_row_text(
        %NormalSection.AlertRow{
          alert: %Alert{
            active_period: active_period,
            effect: effect,
            informed_entities: informed_entities
          },
          routes: [%Route{id: route_id} | _],
          displayed_headsign: headsign,
          location: location
        },
        now
      )
      when effect in [:suspension, :shuttle] do
    header_text =
      %FreeTextLine{
        icon: nil,
        text:
          if location == :inside do
            if effect == :shuttle do
              ["No #{route_id} Line service", %{special: :break}, "Use Shuttle Buses"]
            else
              ["No #{route_id} Line trains"]
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
      Screens.Alerts.Endpoints.get_endpoints(informed_entities, route_id)

    endpoint_text = [
      "from",
      %{format: "bold", text: min_full_name},
      "to",
      %{format: "bold", text: max_full_name}
    ]

    end_time = AlertTextUtil.end_time_text(active_period, now)

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
          stop_name: stop_name
        },
        _now
      )
      when effect in [:station_closure, :stop_closure] do
    header_text =
      %FreeTextLine{
        icon: nil,
        text:
          if location == :inside do
            ["Trains skip #{stop_name}"]
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
