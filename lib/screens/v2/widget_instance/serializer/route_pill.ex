defmodule Screens.V2.WidgetInstance.Serializer.RoutePill do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.RouteType

  @type t :: text_pill() | icon_pill() | slashed_route_pill()

  @type text_pill :: %{
          type: :text,
          text: String.t(),
          color: color()
        }

  @type icon_pill :: %{
          type: :icon,
          icon: :rail | :boat,
          color: color()
        }

  @type slashed_route_pill :: %{
          type: :slashed,
          part1: String.t(),
          part2: String.t(),
          color: color()
        }

  @type color :: :red | :orange | :green | :blue | :purple | :yellow | :teal

  @sl_route_ids ~w[741 742 743 746 749 751]

  @ct_route_ids ~w[708 747]

  @spec serialize_for_departure(Route.id(), String.t(), RouteType.t(), pos_integer() | nil) :: t()
  def serialize_for_departure(route_id, route_name, route_type, track_number) do
    route =
      cond do
        not is_nil(track_number) ->
          %{type: :text, text: "TR#{track_number}"}

        route_type == :rail ->
          %{type: :icon, icon: :rail}

        route_type == :ferry ->
          %{type: :icon, icon: :boat}

        String.contains?(route_name, "/") ->
          [part1, part2] = String.split(route_name, "/")
          %{type: :slashed, part1: part1, part2: part2}

        true ->
          do_serialize(route_id, route_name: route_name)
      end

    Map.merge(route, %{color: get_color_for_route(route_id, route_type)})
  end

  @spec serialize_for_alert(Route.id()) :: t()
  def serialize_for_alert(route_id) do
    route = do_serialize(route_id, gl_branch: true, cr_abbrev: true, ferry_abbrev: true)

    Map.merge(route, %{color: get_color_for_route(route_id)})
  end

  @typep bool_opt :: :gl_branch | :cr_abbrev | :ferry_abbrev
  @typep serialize_opt :: {bool_opt(), boolean()} | {:route_name, String.t()}
  @typep serialize_opts :: list(serialize_opt())

  @spec do_serialize(Route.id(), serialize_opts()) :: map()
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp do_serialize(route_id, opts)

  defp do_serialize("Red", _), do: %{type: :text, text: "RL"}
  defp do_serialize("Mattapan", _), do: %{type: :text, text: "M"}
  defp do_serialize("Orange", _), do: %{type: :text, text: "OL"}

  defp do_serialize("Green-" <> branch, opts) do
    %{type: :text, text: if(opts[:gl_branch], do: "GL·" <> branch, else: "GL")}
  end

  defp do_serialize("Blue", _), do: %{type: :text, text: "BL"}

  defp do_serialize("CR-" <> line, opts) do
    if opts[:cr_abbrev] do
      line_abbrev =
        case line do
          "Haverhill" -> "HVL"
          "Newburyport" -> "NBP"
          "Lowell" -> "LWL"
          "Fitchburg" -> "FBG"
          "Worcester" -> "WOR"
          "Needham" -> "NDM"
          "Franklin" -> "FRK"
          "Providence" -> "PVD"
          "Fairmount" -> "FMT"
          "Middleborough" -> "MID"
          "Kingston" -> "KNG"
          "Greenbush" -> "GRB"
        end

      %{type: :text, text: line_abbrev}
    else
      %{type: :icon, icon: :rail}
    end
  end

  defp do_serialize("Boat-" <> line, opts) do
    if opts[:ferry_abbrev] do
      case line do
        "F1" -> %{type: :slashed, part1: "HNG", part2: "HUL"}
        "F4" -> %{type: :text, text: "CTN"}
      end
    else
      %{type: :icon, icon: :boat}
    end
  end

  defp do_serialize(route_id, _) when route_id in @sl_route_ids do
    text =
      case route_id do
        "741" -> "SL1"
        "742" -> "SL2"
        "743" -> "SL3"
        "751" -> "SL4"
        "749" -> "SL5"
        "746" -> "SLW"
      end

    %{type: :text, text: text}
  end

  defp do_serialize(route_id, _) when route_id in @ct_route_ids do
    text =
      case route_id do
        "747" -> "CT2"
        "708" -> "CT3"
      end

    %{type: :text, text: text}
  end

  defp do_serialize(route_id, opts) do
    route_name = Keyword.get(opts, :route_name, "")

    %{
      type: :text,
      text: if(not is_nil(route_name) and route_name != "", do: route_name, else: route_id)
    }
  end

  defp get_color_for_route(route_id, route_type \\ nil)

  defp get_color_for_route("Red", _), do: :red
  defp get_color_for_route("Mattapan", _), do: :red
  defp get_color_for_route("Orange", _), do: :orange
  defp get_color_for_route("Green-" <> _, _), do: :green
  defp get_color_for_route("Blue", _), do: :blue
  defp get_color_for_route("CR-" <> _, _), do: :purple
  defp get_color_for_route("Boat-" <> _, _), do: :teal

  defp get_color_for_route(route_id, _)
       when route_id in @sl_route_ids,
       do: :silver

  defp get_color_for_route(_, :rail), do: :purple
  defp get_color_for_route(_, :ferry), do: :teal
  defp get_color_for_route(_, _), do: :yellow
end
