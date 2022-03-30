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
          icon: icon(),
          color: color()
        }

  @type slashed_route_pill :: %{
          type: :slashed,
          part1: String.t(),
          part2: String.t(),
          color: color()
        }

  @type audio_route :: %{
          route_text: String.t(),
          vehicle_type: :train | :bus | :trolley | :ferry | nil,
          track_number: pos_integer() | nil
        }

  @type icon :: :bus | :light_rail | :rail | :boat

  @type color :: :red | :orange | :green | :blue | :purple | :yellow | :teal

  @sl_route_ids ~w[741 742 743 746 749 751]

  @cr_line_abbreviations %{
    "Haverhill" => "HVL",
    "Newburyport" => "NBP",
    "Lowell" => "LWL",
    "Fitchburg" => "FBG",
    "Worcester" => "WOR",
    "Needham" => "NDM",
    "Franklin" => "FRK",
    "Providence" => "PVD",
    "Fairmount" => "FMT",
    "Middleborough" => "MID",
    "Kingston" => "KNG",
    "Greenbush" => "GRB"
  }

  @special_bus_route_names %{
    "741" => "SL1",
    "742" => "SL2",
    "743" => "SL3",
    "751" => "SL4",
    "749" => "SL5",
    "746" => "SLW",
    "747" => "CT2",
    "708" => "CT3"
  }

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
          do_serialize(route_id, %{route_name: route_name})
      end

    Map.put(route, :color, get_color_for_route(route_id, route_type))
  end

  @spec serialize_for_audio_departure(Route.id(), String.t(), RouteType.t(), pos_integer() | nil) ::
          audio_route()
  def serialize_for_audio_departure(route_id, route_name, route_type, track_number) do
    vehicle_type =
      case {route_type, route_id} do
        # "Trolley" is part of the route name
        {:light_rail, "Mattapan"} -> nil
        {:light_rail, "Green-" <> _} -> :train
        {:subway, _} -> :train
        {:rail, _} -> :train
        # "Ferry" is part of the route name
        {:ferry, _} -> nil
        {other, _} -> other
      end

    %{
      route_text: route_name,
      vehicle_type: vehicle_type,
      track_number: track_number
    }
  end

  @spec serialize_route_type_for_alert(RouteType.t()) :: t()
  def serialize_route_type_for_alert(:light_rail) do
    %{type: :icon, icon: :light_rail, color: :green}
  end

  def serialize_route_type_for_alert(:rail) do
    %{type: :icon, icon: :rail, color: :purple}
  end

  def serialize_route_type_for_alert(:bus) do
    %{type: :icon, icon: :bus, color: :yellow}
  end

  def serialize_route_type_for_alert(:ferry) do
    %{type: :icon, icon: :boat, color: :teal}
  end

  @spec serialize_route_for_alert(Route.id()) :: t()
  def serialize_route_for_alert(route_id) do
    route = do_serialize(route_id, %{gl_long: true, gl_branch: true, cr_abbrev: true})

    Map.merge(route, %{color: get_color_for_route(route_id)})
  end

  def serialize_route_for_reconstructed_alert(route_id_group, opts \\ %{})

  def serialize_route_for_reconstructed_alert({"Green", branches}, opts) do
    route = do_serialize("Green", opts)

    Map.merge(route, %{
      color: :green,
      branches: Enum.map(branches, fn "Green-" <> branch -> branch end)
    })
  end

  def serialize_route_for_reconstructed_alert({route_id, _}, opts) do
    route = do_serialize(route_id, opts)
    Map.merge(route, %{color: get_color_for_route(route_id)})
  end

  @typep serialize_opts :: %{
           optional(:gl_branch) => boolean(),
           optional(:gl_long) => boolean(),
           optional(:cr_abbrev) => boolean(),
           optional(:route_name) => String.t(),
           optional(:large) => boolean()
         }

  @spec do_serialize(Route.id(), serialize_opts()) :: map()
  defp do_serialize(route_id, opts)

  defp do_serialize(route, %{large: true}),
    do: %{type: :text, text: String.upcase("#{route} line")}

  defp do_serialize("Red", _), do: %{type: :text, text: "RL"}
  defp do_serialize("Mattapan", _), do: %{type: :text, text: "M"}
  defp do_serialize("Orange", _), do: %{type: :text, text: "OL"}
  defp do_serialize("Green", _), do: %{type: :text, text: "GL"}

  defp do_serialize("Green-" <> branch, %{gl_branch: true} = opts) do
    %{type: :text, text: if(opts[:gl_long], do: "Green Line ", else: "GL·") <> branch}
  end

  defp do_serialize("Green-" <> _branch, %{gl_long: true}) do
    %{type: :text, text: "Green Line"}
  end

  defp do_serialize("Green-" <> _branch, _) do
    %{type: :text, text: "GL"}
  end

  defp do_serialize("Blue", _), do: %{type: :text, text: "BL"}

  for {line, abbrev} <- @cr_line_abbreviations do
    defp do_serialize("CR-" <> unquote(line), %{cr_abbrev: true}) do
      %{type: :text, text: unquote(abbrev)}
    end
  end

  defp do_serialize("CR-" <> _line, _) do
    %{type: :icon, icon: :rail}
  end

  defp do_serialize("Boat-" <> _line, _) do
    %{type: :icon, icon: :boat}
  end

  for {route_id, name} <- @special_bus_route_names do
    defp do_serialize(unquote(route_id), _) do
      %{type: :text, text: unquote(name)}
    end
  end

  defp do_serialize(route_id, opts) do
    route_name = Map.get(opts, :route_name, "")

    %{
      type: :text,
      text: if(route_name != "", do: route_name, else: route_id)
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
