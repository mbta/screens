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
    {alert_keyed_sections, normal_keyed_sections} =
      sections_map
      |> put_in_order()
      |> Enum.split_with(fn {_line, section} -> has_at_least_one_alert?(section) end)

    render_split_keyed_sections(alert_keyed_sections, normal_keyed_sections)
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
      ~E|<s>The <%= normal_line_name1 %> and the <%= normal_line_name2 %> have normal service</s>|

    ~E|<%= alert_sections_rendered %><%= normal_sections_rendered %>|
  end

  # 3 or 4 lines have alert(s). We list the disrupted lines first, with no conjunctions (e.g. "and") between them.
  # If one of the lines has normal service--so, 3 lines have alert(s)--it goes last.
  defp render_split_keyed_sections(alert_keyed_sections, normal_keyed_sections) do
    normal_section_rendered =
      case normal_keyed_sections do
        [] -> ~E||
        [{line_key, _}] -> ~E|<s>The <%= key_to_line_name(line_key) %> has normal service</s>|
      end

    alert_sections_rendered = Enum.map(alert_keyed_sections, &render_section/1)

    ~E|<%= alert_sections_rendered %><%= normal_section_rendered %>|
  end

  # =============================================================================#
  # render_section will only be called on sections that have at least one alert. #
  # =============================================================================#
  @spec render_section({line_atom, SubwayStatus.section()}) :: ssml_blob
  defp render_section({:green, section}) do
    # Special logic for the GL section:
    # - List out branches on alerts
    # - If there are multiple alerts and at least one is a branch alert, read them out as separate sentences instead of connecting with ", and "
    alerts = get_alerts(section)

    if length(alerts) > 1 and Enum.any?(alerts, &branch_alert?/1) do
      Enum.map(alerts, fn alert -> ~E|<s><%= render_gl_alert(alert) %></s>| end)
    else
      alerts
      |> Enum.map(&render_gl_alert/1)
      |> Enum.intersperse(~E|, and |)
      |> then(fn sentence -> ~E|<s><%= sentence %></s>| end)
    end
  end

  defp render_section({line_key, section}) do
    line_name = key_to_line_name(line_key)

    section
    |> get_alerts()
    |> Enum.map(&render_non_gl_alert(&1, line_name))
    |> Enum.intersperse(~E|, and |)
    |> then(fn sentence -> ~E|<s><%= sentence %></s>| end)
  end

  defp render_non_gl_alert(alert, line_name) do
    {verb_atom, content} = render_status_and_location(alert)

    ~E|The <%= line_name %> <%= conjugate(verb_atom, false) %> <%= content %>|
  end

  defp render_gl_alert(alert) do
    {verb_atom, content} = render_status_and_location(alert)
    branch_count = get_branch_count(alert)
    multi_branch_alert? = branch_count > 1
    trunk? = branch_count == 0

    maybe_the = if trunk?, do: "The ", else: ""

    ~E|<%= maybe_the %><%= render_gl_branch_or_line(alert) %> <%= conjugate(verb_atom, multi_branch_alert?) %> <%= content %>|
  end

  @spec render_gl_branch_or_line(SubwayStatus.alert()) :: ssml_blob
  defp render_gl_branch_or_line(%{route_pill: %{branches: branches}}) when length(branches) > 0 do
    branch_or_branches = if length(branches) == 1, do: "branch", else: "branches"

    {all_but_last, last} =
      branches
      |> Enum.map(fn letter ->
        ~E|<say-as interpret-as="spell-out"><%= String.upcase(to_string(letter)) %></say-as>|
      end)
      |> Enum.split(-1)

    # b
    # b, and, c
    # b, c, and, d
    # b, c, d, and, e - exceptionally rare edge case
    # (Excessive comma use makes Polly pronounce the letters more clearly.)
    letters_rendered =
      if all_but_last == [] do
        last
      else
        comma_separated_all_but_last = Enum.intersperse(all_but_last, ~E|, |)
        ~E|<%= comma_separated_all_but_last %>, and, <%= last %>|
      end

    # This deviates slightly from designs. The letters are read out after "branch(es)"
    # instead of before, because Polly pronounces that ordering much more clearly for some reason.
    ~E|Green Line <%= branch_or_branches %>, <%= letters_rendered %>,|
    #                                      ^                        ^
    #                                      Added to improve clarity of the first and last letters
  end

  defp render_gl_branch_or_line(_non_branch_alert), do: ~E|Green Line|

  # Returns the text for the status and location (e.g. "Shuttle Bus from Back Bay to North Station"),
  # as well as an atom indicating what verb should be used to link it to the text for the subway line/branches.
  #
  # The calling function is responsible for conjugating the verb according to the number of the subway line/branches.
  # For example, if `render_status_and_location` returns `{:is, content}` and it's for a single line,
  # the caller should conjugate the verb to "is".
  # If it's for a set of 2 or more GL branches, the caller should conjugate the verb to "are".
  @spec render_status_and_location(SubwayStatus.alert()) :: {:is | :has, ssml_blob}
  defp render_status_and_location(%{status: status, location: location}) do
    location_string = get_location_string(location)

    # To avoid awkward-sounding alert descriptions, we need to adjust wording/punctuation
    # based on the values of status and location_string.
    #
    # alert.status                   ||| possible values of location_string
    # -------------------------------|||-----------------------------------
    # SERVICE SUSPENDED              ||| Entire line
    # Suspension                     ||| "" | Xbound | $STATION | $STATION ↔ $STATION
    # Service Change                 ||| "" | Xbound | $STATION | $STATION ↔ $STATION | Entire line
    # Shuttle Bus                    ||| "" | Xbound | $STATION | $STATION ↔ $STATION | Entire line
    # Delays (up to|over) $N minutes ||| "" | Xbound | $STATION | $STATION ↔ $STATION | Due to $CAUSE
    # Stop Skipped                   ||| "" | $STOP | $STOP and $STOP | $STOP, $STOP, and $STOP
    # $N Stops Skipped               ||| ""
    # $N current alerts              ||| ""
    # Single Tracking                ||| Due to $CAUSE
    verb_atom = get_verb_atom(status)
    article = get_article(status, location_string)
    content = get_content(status, location_string)

    {verb_atom, ~E|<%= article %><%= content %>|}
  end

  defp get_verb_atom("Stop Skipped" <> _), do: :is
  defp get_verb_atom("Single Tracking" <> _), do: :is

  defp get_verb_atom(status) do
    cond do
      String.ends_with?(status, "Stops Skipped") -> :is
      true -> :has
    end
  end

  defp conjugate(verb_atom, multi_branch_alert?)

  defp conjugate(:is, false), do: "is"
  defp conjugate(:is, true), do: "are"

  defp conjugate(:has, false), do: "has"
  defp conjugate(:has, true), do: "have"

  defp get_article(status, location_string) do
    cond do
      location_string == "Eastbound" -> "an "
      status =~ ~r/^(?:Delays|Stop Skipped|Single Tracking|SERVICE SUSPENDED|\d)/ -> ""
      true -> "a "
    end
  end

  defp get_content("Stop Skipped", ""), do: ~E|skipping 1 stop|

  defp get_content(status, location_string) do
    stops_skipped_match = Regex.run(~r/^(?:(\d+)\s)?Stops? Skipped$/, status)

    cond do
      location_string == "" and stops_skipped_match ->
        # E.g. "2 Stops Skipped", "5 Stops Skipped",
        [_, num_stops_skipped] = stops_skipped_match

        stops = String.to_integer(num_stops_skipped)
        stop_word = if stops == 1, do: "stop", else: "stops"
        ~E|skipping <%= stops %> <%= stop_word %>|

      location_string == "" ->
        # E.g. "3 current alerts", "Suspension"
        ~E|<%= status %>|

      # Location is actually a cause (single tracking)
      String.starts_with?(location_string, "Due to") ->
        ~E|<%= status %> <%= location_string %>|

      # Shuttle Bus/Suspension/Delays + Xbound
      location_string =~ ~r/^(?:North|East|South|West)bound$/ ->
        # E.g. "Southbound Shuttle bus", "Northbound Suspension", "Eastbound Delays up to 20 minutes"
        ~E|<%= location_string %> <%= status %>|

      # Shuttle Bus/Suspension/Delays/Single Tracking + $STATION ↔ $STATION
      String.contains?(location_string, " ↔ ") ->
        # E.g. "Suspension between Back Bay and North Station", "Shuttle Bus between Ashmont and JFK/UMass"
        ~E|<%= status %> between <%= String.replace(location_string, " ↔ ", " and ") %>|

      # Shuttle Bus/Service Change/SERVICE SUSPENDED + Entire line
      location_string == "Entire line" ->
        # "SERVICE SUSPENDED on the Entire line"
        ~E|<%= status %> on the <%= location_string %>|

      # Shuttle Bus/Suspension/Delays + $STATION
      status =~ ~r/^(?:Shuttle Bus|Suspension|Delays)/ ->
        # E.g. "Suspension at Quincy Center"
        ~E|<%= status %> at <%= location_string %>|

      # Skipping + $STOP | $STOP and $STOP | $STOP, $STOP, and $STOP
      true ->
        # E.g. "Skipping Park Street, Downtown Crossing, and South Station"
        ~E|skipping <%= location_string %>|
    end
  end

  defp get_location_string(nil), do: ""

  # We never read out the alerts URL.
  defp get_location_string(%{full: "mbta.com" <> _}), do: ""
  defp get_location_string("mbta.com" <> _), do: ""

  defp get_location_string(%{full: full}), do: full
  defp get_location_string(location_string), do: location_string

  # Converts the serialized map to an ordered list, since we can't rely on consistent enumeration order for maps.
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

  defp get_branch_count(%{route_pill: %{branches: branches}}), do: length(branches)
  defp get_branch_count(_alert), do: 0

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
