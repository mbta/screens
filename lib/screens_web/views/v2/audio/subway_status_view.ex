defmodule ScreensWeb.V2.Audio.SubwayStatusView do
  use ScreensWeb, :view

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  def render("_widget.ssml", %{blue: blue, orange: orange, red: red, green: green}) do
    ~E|
    <p><%= render_route(blue) %></p>
    <p><%= render_route(orange) %></p>
    <p><%= render_route(red) %></p>
    <p><%= render_green_line(green) %></p>
    <p><%= render_gl_branch_health_check(green) %></p>
    |
  end

  defp render_route(%{route: %{color: color}, status: status} = route) do
    "#{color} line: #{status}: #{render_location(route)}"
  end

  defp render_green_line(%{route: %{color: :green}, status: status, type: :single} = route) do
    "Green Line: #{render_branches(route)} #{status}: #{render_location(route)}"
  end

  defp render_green_line(%{statuses: statuses, type: :multiple}) do
    Enum.map_join(statuses, ": ", &render_gl_status/1)
  end

  defp render_gl_status([branches, status]) do
    "Green Line: #{render_branches(branches)}: #{status}"
  end

  defp render_branches(%{branch: "Green-" <> branch}), do: "#{branch} Branch"
  defp render_branches(["Green-" <> branch]), do: "#{branch} Branch"
  defp render_branches(["Green-" <> b1, "Green-" <> b2]), do: "#{b1} and #{b2} Branches"

  defp render_branches([_] = branches) do
    branch_letters = Enum.map(branches, fn "Green-" <> branch -> branch end)

    all_but_last_joined =
      branch_letters
      |> Enum.take(length(branches) - 1)
      |> Enum.join(", ")

    all_but_last_joined <> "and #{List.last(branch_letters)} Branches"
  end

  defp render_branches(_), do: ""

  defp render_gl_branch_health_check(%{branch: branch, type: :single}) do
    render_health_check(@green_line_branches -- [branch])
  end

  defp render_gl_branch_health_check(%{statuses: statuses, type: :multiple}) do
    unaffected_branches =
      @green_line_branches -- Enum.flat_map(statuses, fn [branches, _] -> branches end)

    render_health_check(unaffected_branches)
  end

  defp render_health_check(["Green-" <> unaffected_branch]),
    do: "Green Line #{unaffected_branch}: Normal Service"

  defp render_health_check([]), do: ""
  defp render_health_check(_), do: "Other Green Line branches: Normal Service"

  defp render_location(%{location: %{full: "mbta.com/alerts/subway"}}), do: ""
  defp render_location(%{location: %{full: location}}), do: location
  defp render_location(_), do: ""
end
