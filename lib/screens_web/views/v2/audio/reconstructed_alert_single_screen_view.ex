defmodule ScreensWeb.V2.Audio.ReconstructedAlertSingleScreenView do
  use ScreensWeb, :view

  alias Screens.Alerts.Alert
  alias Screens.Util

  def render("_widget.ssml", alert) do
    ~E|<p><%= render_banner(alert) %><%= render_alert(alert) %></p>|
  end

  # The field `unaffected_routes` is reserved for single line closures at transfer station
  def render_banner(%{
        unaffected_routes: _unaffected_routes
      }),
      do: nil

  # The field `region` is reserved for single-pane alerts.
  # Routes will only be empty if the banner should be empty (e.g. multiline delay)
  def render_banner(%{region: _region, routes: []}), do: ~E|Attention, riders. |

  def render_banner(%{
        region: _region,
        routes: routes
      }) do
    if routes |> hd() |> Map.has_key?(:headsign) do
      destinations = Enum.map(routes, fn route -> route.headsign end)

      if length(destinations) < 3 do
        ~E|Attention, riders to <%= Util.format_name_list_to_string_audio(destinations) %>. |
      else
        ~E|Attention, riders. |
      end
    else
      ~E|Attention, <%= hd(routes).route_id %> line riders. |
    end
  end

  def render_banner(_), do: nil

  # Delay
  def render_alert(
        %{
          effect: :delay,
          issue: issue
        } = alert
      ) do
    ~E|<%= issue %><%= render_cause(alert.cause) %>.|
  end

  # Downstream closure
  def render_alert(%{
        region: :outside,
        effect: :station_closure,
        routes: route_svg_names,
        cause: cause,
        stations: stations
      }) do
    ~E|<%= get_line_name(route_svg_names) %> trains are skipping <%= Util.format_name_list_to_string_audio(stations) %><%= render_cause(cause) %>. Please seek an alternate route.|
  end

  # Downstream shuttle
  def render_alert(%{
        region: :outside,
        effect: :shuttle,
        routes: route_svg_names,
        endpoints: {left_endpoint, right_endpoint},
        cause: cause
      }) do
    ~E|Shuttle buses replace <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %><%= render_cause(cause) %>. All shuttle buses are accessible.|
  end

  # Downstream suspension
  def render_alert(%{
        region: :outside,
        effect: :suspension,
        routes: route_svg_names,
        endpoints: {left_endpoint, right_endpoint},
        cause: cause
      }) do
    ~E|There are no <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %><%= render_cause(cause) %>. Please seek an alternate route.|
  end

  # Boundary shuttle
  def render_alert(%{
        region: :boundary,
        effect: :shuttle,
        issue: issue,
        routes: route_svg_names,
        endpoints: {left_endpoint, right_endpoint},
        cause: cause
      }) do
    ~E|There are <%= issue %>. Please use the shuttle bus. Shuttle buses are replacing <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %><%= render_cause(cause) %>. All shuttle buses are accessible.|
  end

  # Boundary suspension
  def render_alert(%{
        region: :boundary,
        effect: :suspension,
        issue: issue,
        routes: route_svg_names,
        endpoints: {left_endpoint, right_endpoint},
        cause: cause
      }) do
    ~E|There are <%= issue %>. Please seek an alternate route. Please note that there are no <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %><%= render_cause(cause) %>.|
  end

  # Closure here - three cases

  # Case 1: Multiple stations, single line impacted
  def render_alert(%{
        effect: :station_closure,
        routes: route_svg_names,
        cause: cause,
        other_closures: other_closures
      })
      when other_closures != [] do
    ~E|This station is closed<%= render_cause(cause) %>. Please seek an alternate route. <%= get_line_name(route_svg_names) %> trains are skipping this station and <%= Util.format_name_list_to_string_audio(other_closures) %>.|
  end

  # Case 2: Single line impacted at transfer station
  def render_alert(%{
        effect: :station_closure,
        routes: route_svg_names,
        cause: cause,
        unaffected_routes: unaffected_routes
      }) do
    ~E|<%= get_line_name(route_svg_names) %> trains are skipping this station<%= render_cause(cause) %>. Please seek an alternate route. <%= get_line_name(unaffected_routes) %> trains are stopping here as usual.|
  end

  # Case 3: Single station, single line impacted
  # The pattern to match is very simple here, because other station closures will
  # be caught by previous clauses, so this pattern is specifically for a closure here
  def render_alert(%{
        effect: :station_closure,
        routes: route_svg_names,
        cause: cause
      }) do
    ~E|This station is closed<%= render_cause(cause) %>. Please seek an alternate route. <%= get_line_name(route_svg_names) %> trains are skipping this station.|
  end

  # Shuttle here
  def render_alert(
        %{
          effect: :shuttle,
          routes: route_svg_names,
          endpoints: {left_endpoint, right_endpoint},
          cause: cause
        } = alert
      ) do
    if Map.has_key?(alert, :is_transfer_station) do
      ~E|There are no <%= get_line_name(route_svg_names) %> trains. Please use the shuttle bus. Shuttle buses are replacing <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %><%= render_cause(cause) %>. All shuttle buses are accessible.|
    else
      ~E|This station is closed. Please use the shuttle bus. Shuttle buses are replacing <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %><%= render_cause(cause) %>. All shuttle buses are accessible.|
    end
  end

  # Suspension here
  def render_alert(
        %{
          effect: :suspension,
          routes: route_svg_names,
          endpoints: {left_endpoint, right_endpoint},
          cause: cause
        } = alert
      ) do
    if Map.has_key?(alert, :is_transfer_station) do
      ~E|There are no <%= get_line_name(route_svg_names) %> trains<%= render_cause(cause) %>. Please seek an alternate route. Please note that there are no <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %>.|
    else
      ~E|This station is closed<%= render_cause(cause) %>. Please seek an alternate route. Please note that there are no <%= get_line_name(route_svg_names) %> trains between <%= left_endpoint %> and <%= right_endpoint %>.|
    end
  end

  # Fallback
  def render_alert(%{
        issue: issue,
        remedy: remedy,
        remedy_bold: remedy_bold
      }) do
    if !is_nil(remedy_bold) do
      ~E|<%= remedy_bold %>.|
    else
      ~E|<%= issue %>. <%= remedy %>|
    end
  end

  defp get_line_name([%{color: _color, text: _text, type: _type} | _tail] = routes) do
    routes
    |> Enum.map(fn route -> route.text end)
    |> Util.format_name_list_to_string_audio()
  end

  defp get_line_name(routes) do
    route_ids =
      routes
      |> Enum.map(fn route -> route.route_id end)

    branch_letters = for "Green-" <> branch_letter <- route_ids, do: branch_letter

    lines_without_branches =
      route_ids
      |> Enum.reject(&String.contains?(&1, "Green-"))
      |> Enum.map(fn line -> line <> " Line" end)

    branch_or_branches = if length(branch_letters) == 1, do: "branch", else: "branches"

    formatted_lines_with_branches =
      if branch_letters !== [],
        do: [
          "Green Line #{branch_or_branches}, " <>
            Util.format_name_list_to_string_audio(branch_letters)
        ],
        else: []

    list_of_lines =
      (formatted_lines_with_branches ++ lines_without_branches)
      |> Util.format_name_list_to_string()

    ~E|<%= list_of_lines %>|
  end

  defp render_cause(nil), do: nil
  defp render_cause(cause), do: " #{Alert.get_cause_string(cause)}"
end
