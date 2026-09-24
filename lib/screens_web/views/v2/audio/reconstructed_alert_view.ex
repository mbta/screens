defmodule ScreensWeb.V2.Audio.ReconstructedAlertView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        issue: issue,
        remedy: remedy,
        cause: cause,
        region: :outside,
        effect: :station_closure
      }) do
    ~E|<p><%= render_issue(issue) %> <%= cause %>.<%= render_remedy(remedy) %></p>|
  end

  def render("_widget.ssml", %{
        issue: issue,
        routes: routes,
        urgent: false,
        effect: effect
      })
      when effect === :delay do
    ~E|<p><%= render_affected_routes(routes) %> delay. <%= render_issue(issue) %>.</p>|
  end

  # Fix "alternate" pronunciation
  def render("_widget.ssml", %{
        issue: issue,
        remedy: remedy,
        cause: cause,
        location: location,
        routes: routes,
        effect: effect
      }) do
    ~E|<p><%= render_affected_routes(routes) %> alert. <%= render_issue_details(issue, location, cause) %>.<%= render_remedy(remedy) %><%= render_additional_info_for_effect(effect) %></p>|
  end

  defp render_issue([full_issue | _]), do: render_issue(full_issue)

  defp render_issue(%{text: text}) do
    Enum.map_join(text, " ", fn
      %{route: route} -> "#{route} line"
      text -> text
    end)
  end

  defp render_issue(text), do: text

  defp render_issue_details(issue, location, cause) do
    [render_issue(issue), location, cause]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp render_affected_routes(routes) do
    non_gl_text = get_non_gl_text(routes)

    gl_text = get_gl_text(routes)

    cond do
      String.length(non_gl_text) == 0 -> gl_text
      String.length(gl_text) == 0 -> non_gl_text
      true -> non_gl_text <> " and " <> gl_text
    end
  end

  # Builds the text for GL as long as at least one branch is not affected.
  # Uses hd() because there will only ever be one GL item in routes.
  defp get_gl_text(routes) do
    routes
    |> Enum.filter(&Map.has_key?(&1, :branches))
    |> Enum.map(fn
      %{branches: [branch]} -> "Green Line: #{branch} Branch"
      %{branches: [b1, b2]} -> "Green Line: #{b1} and #{b2} Branches"
      %{branches: [b1, b2, b3]} -> "Green Line: #{b1}, #{b2}, and #{b3} Branches"
    end)
    |> List.first("")
  end

  # Builds the text for non-GL lines and/or GL where all branches are affected.
  defp get_non_gl_text(routes) do
    non_gl_lines =
      routes
      |> Enum.reject(&Map.has_key?(&1, :branches))
      |> Enum.map(fn %{color: color} -> color end)

    case non_gl_lines do
      [] ->
        ""

      [route] ->
        "#{route} Line"

      routes when length(routes) == 2 ->
        joined_text =
          routes
          |> Enum.join(" and ")

        joined_text <> " Lines"

      routes when length(routes) > 2 ->
        all_but_last =
          routes
          |> Enum.take(length(routes) - 1)
          |> Enum.join(", ")

        all_but_last <> ", and #{List.last(routes)} Lines"
    end
  end

  defp render_additional_info_for_effect(effect) do
    case effect do
      :shuttle -> " All shuttle buses are accessible."
      _ -> ""
    end
  end

  defp render_remedy(remedy) when remedy in [nil, ""], do: ""
  defp render_remedy(remedy), do: " #{adjust_remedy(remedy)}."

  defp adjust_remedy("Seek alternate route"), do: "Please seek an alternate route"

  defp adjust_remedy(remedy), do: remedy
end
