defmodule ScreensWeb.V2.Audio.SubwayStatusView do
  use ScreensWeb, :view

  alias Screens.V2.WidgetInstance.SubwayStatus

  @ordered_line_keys ~w[blue orange red green]a

  @type line_atom :: :blue | :orange | :red | :green

  @type ssml_blob :: any

  def render("_widget.ssml", sections_map) do
    ~E|<p><s>Subway service overview</s><%= render_sections(sections_map) %></p>|
  end

  defp render_sections(sections_map) do
    sections_map
    |> put_in_order()
    |> Enum.split_with(fn {_line, section} -> has_at_least_one_alert?(section) end)
    |> then(fn {alert_keyed_sections, normal_keyed_sections} ->
      render_split_keyed_sections(alert_keyed_sections, normal_keyed_sections)
    end)
  end

  # 0 system alerts.
  defp render_split_keyed_sections([], _) do
    ~E|<s>All lines have normal service</s>|
  end

  # 1 line has an alert(s).
  defp render_split_keyed_sections([alert_keyed_section], _) do
    ~E|<%= render_section(alert_keyed_section) %><s>All other lines have normal service</s>|
  end

  # 2 lines have alert(s). We list the disrupted lines first, then the normal-status lines.
  defp render_split_keyed_sections(
         [alert_keyed_section1, alert_keyed_section2],
         normal_keyed_sections
       ) do
    [normal_line_name1, normal_line_name2] =
      Enum.map(normal_keyed_sections, fn {line_key, _} -> key_to_line_name(line_key) end)

    alert_sections_rendered =
      ~E|<%= render_section(alert_keyed_section1) %><%= render_section(alert_keyed_section2) %>|

    normal_sections_rendered =
      ~E|<s><%= normal_line_name1 %>, and <%= normal_line_name2 %>: normal service</s>|

    ~E|<%= alert_sections_rendered %><%= normal_sections_rendered %>|
  end

  # 3 or 4 lines have alert(s). We list the disrupted lines first, with no conjunctions (e.g. "and") between them.
  # If one of the lines has normal service--so, 3 lines have alert(s)--it goes last.
  defp render_split_keyed_sections(alert_keyed_sections, normal_keyed_sections) do
    normal_section_rendered =
      case normal_keyed_sections do
        [] -> ~E||
        [{line_key, _}] -> ~E|<s><%= key_to_line_name(line_key) %>: normal service</s>|
      end

    alert_sections_rendered = Enum.map(alert_keyed_sections, &render_section/1)

    ~E|<%= alert_sections_rendered %><%= normal_section_rendered %>|
  end

  # ============================================================================#
  # render_section will only be called on sections that have at least one alert. #
  # ============================================================================#
  defp render_section({:green, section}) do
    # Special logic for the GL section:
    # - List out branches on alerts
    # - If there are 2 alerts and at least one is a branch alert, read them out as separate sentences instead of connecting with ", and "
    alerts = get_alerts(section)

    if length(alerts) == 2 and Enum.any?(alerts, &branch_alert?/1) do
      Enum.map(alerts, fn alert ->
        ~E|<s><%= render_gl_branch_or_line(alert) %>: <%= render_alert(alert) %></s>|
      end)
    else
      alerts
      |> Enum.map(fn alert ->
        ~E|<%= render_gl_branch_or_line(alert) %>: <%= render_alert(alert) %>|
      end)
      |> Enum.intersperse(~E|, and |)
      |> then(fn sentence -> ~E|<s><%= sentence %></s>| end)
    end
  end

  defp render_section({line_key, section}) do
    line_name = key_to_line_name(line_key)

    section
    |> get_alerts()
    |> Enum.map(fn alert -> ~E|<%= line_name %>: <%= render_alert(alert) %>| end)
    |> Enum.intersperse(~E|, and |)
    |> then(fn sentence -> ~E|<s><%= sentence %></s>| end)
  end

  @spec render_gl_branch_or_line(SubwayStatus.alert()) :: ssml_blob
  defp render_gl_branch_or_line(%{route_pill: %{branches: branches}}) when length(branches) > 0 do
    branch_or_branches = if length(branches) == 1, do: "branch", else: "branches"

    # b
    # b, and, c
    # b, c, and, d
    # b, c, d, and, e - exceptionally rare edge case
    # (Excessive comma use makes Polly pronounce the letters more clearly.)
    {all_but_last, last} =
      branches
      |> Enum.map(fn letter ->
        ~E|<say-as interpret-as="spell-out"><%= String.upcase(Atom.to_string(letter)) %></say-as>|
      end)
      |> Enum.split(-1)

    letters_rendered =
      if all_but_last == [] do
        last
      else
        comma_separated_all_but_last = Enum.intersperse(all_but_last, ~E|, |)
        ~E|<%= comma_separated_all_but_last %>, and, <%= last %> lines|
      end

    # This deviates slightly from designs. The letters are read out after "branch(es)"
    # instead of before, because Polly pronounces that ordering much more clearly for some reason.
    ~E|Green Line <%= branch_or_branches %> <%= letters_rendered %>|
  end

  defp render_gl_branch_or_line(_non_branch_alert), do: ~E|Green Line|

  defp render_alert(alert) do
    location_string = get_location_string(alert.location)

    # To avoid awkward-sounding alert descriptions, we need to adjust wording/punctuation
    # based on the values of alert.status and location_string.
    #
    # alert.status                   ||| possible values of location_string
    # -------------------------------|||-----------------------------------
    # Shuttle Bus                    ||| "" | Xbound | $STATION | $STATION to $STATION | Entire line
    # SERVICE SUSPENDED              ||| Entire line
    # Suspension                     ||| "" | Xbound | $STATION | $STATION to $STATION
    # Delays (up to|over) $N minutes ||| "" | Xbound | $STATION | $STATION to $STATION
    # Bypassing                      ||| "" | $STOP | $STOP and $STOP | $STOP, $STOP, and $STOP
    # Bypassing $N stops             ||| ""
    # $N current alerts              ||| ""
    cond do
      location_string == "" ->
        # E.g. "3 current alerts", "Bypassing 5 stops"
        ~E|<%= alert.status %>|

      # Shuttle Bus/Suspension/Delays + Xbound
      location_string =~ ~r/^(?:North|East|South|West)bound$/ ->
        # E.g. "Southbound Shuttle bus", "Northbound Suspension", "Eastbound Delays up to 20 minutes"
        ~E|<%= location_string %> <%= alert.status %>|

      # Shuttle Bus/Suspension/Delays + $STATION to $STATION
      # Shuttle Bus + Entire line
      # SERVICE SUSPENDED + Entire line
      String.contains?(location_string, " to ") or location_string == "Entire line" ->
        # E.g. "Suspension, Back Bay to North Station", "SERVICE SUSPENDED, Entire line"
        ~E|<%= alert.status %>, <%= location_string %>|

      # Shuttle Bus/Suspension/Delays + $STATION
      alert.status =~ ~r/^(?:Shuttle Bus|Suspension|Delays)/ ->
        # E.g. "Suspension at Quincy Center"
        ~E|<%= alert.status %> at <%= location_string %>|

      # Bypassing + $STOP | $STOP and $STOP | $STOP, $STOP, and $STOP
      true ->
        # E.g. "Bypassing Park Street, Downtown Crossing, and South Station"
        ~E|<%= alert.status %> <%= location_string %>|
    end
  end

  defp get_location_string(nil), do: ""

  # We never read out the alerts URL.
  defp get_location_string(%{full: "mbta.com/alerts"}), do: ""
  defp get_location_string("mbta.com/alerts"), do: ""

  defp get_location_string(%{full: full}), do: full
  defp get_location_string(location_string), do: location_string

  # Converts the serialized map into an ordered list, since we can't rely on consistent enumeration order for maps.
  @spec put_in_order(SubwayStatus.serialized_response()) ::
          list({line_atom, SubwayStatus.section()})
  defp put_in_order(sections_map) do
    Enum.map(@ordered_line_keys, &{&1, Map.fetch!(sections_map, &1)})
  end

  @spec has_at_least_one_alert?(SubwayStatus.section()) :: boolean
  defp has_at_least_one_alert?(section) do
    not match?(%{type: :contracted, alerts: [%{status: "Normal Service"}]}, section)
  end

  @spec branch_alert?(SubwayStatus.alert()) :: boolean
  defp branch_alert?(alert) do
    match?(%{route_pill: %{branches: [_ | _]}}, alert)
  end

  @spec get_alerts(SubwayStatus.section()) :: list(SubwayStatus.alert())
  defp get_alerts(%{type: :contracted} = section) do
    section.alerts
  end

  defp get_alerts(%{type: :extended} = section) do
    [section.alert]
  end

  @spec key_to_line_name(line_atom) :: String.t()
  defp key_to_line_name(line_key) do
    line_key
    |> Atom.to_string()
    |> String.capitalize()
    |> then(&"#{&1} Line")
  end
end
