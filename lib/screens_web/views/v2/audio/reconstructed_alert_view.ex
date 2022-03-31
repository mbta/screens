defmodule ScreensWeb.V2.Audio.ReconstructedAlertView do
  use ScreensWeb, :view

  def render("_widget.ssml", %{
        issue: issue,
        remedy: remedy,
        cause: cause,
        region: :outside,
        effect: :station_closure
      }) do
    ~E|<p><%= issue %> <%= cause %>. <%= remedy %>.</p>|
  end

  def render("_widget.ssml", %{
        issue: issue,
        routes: routes,
        urgent: false,
        effect: effect
      })
      when effect in [:delay, :moderate_delay] do
    ~E|<p><%= render_affected_routes(routes) %> delay. <%= issue %>.</p>|
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
    ~E|<p><%= render_affected_routes(routes) %> alert. <%= render_issue(issue) %> <%= location %> <%= cause %>. <%= remedy %>. <%= render_additional_info_for_effect(effect) %>.</p>|
  end

  defp render_issue(issue) do
    case issue do
      %{text: text} ->
        text
        |> Enum.map_join(" ", fn
          %{icon: icon} -> "#{icon} line"
          text -> text
        end)

      text ->
        text
    end
  end

  defp render_affected_routes(routes) do
    case parse_routes(routes) do
      lines when length(lines) == 1 -> hd(lines)
      [l1, l2] -> "#{l1} and #{l2} line"
      [l1, l2, l3] -> "#{l1}, #{l2}, and #{l3} line"
    end
  end

  defp parse_routes(routes) do
    routes
    |> Enum.sort_by(fn
      %{branches: _} -> 1
      _ -> 0
    end)
    |> Enum.map(fn
      %{branches: [branch]} -> "Green Line: #{branch} Branch"
      %{branches: [b1, b2]} -> "Green Line: #{b1} and #{b2} Branches"
      %{branches: [b1, b2, b3]} -> "Green Line: #{b1}, #{b2}, and #{b3} Branches"
      %{branches: _branches} -> "Green Line"
      %{color: color} -> "#{color} Line"
    end)
  end

  defp render_additional_info_for_effect(effect) do
    case effect do
      :shuttle -> "All shuttle buses are accessible"
      _ -> ""
    end
  end
end
