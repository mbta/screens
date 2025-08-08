defmodule Screens.V2.WidgetInstance.Serializer.RoutePill do
  @moduledoc false

  alias Screens.Report
  alias Screens.Routes.Route
  alias Screens.RouteType

  @type t :: text_pill() | icon_pill() | slashed_route_pill()

  @type text_pill :: %{
          type: :text,
          text: String.t(),
          route_abbrev: String.t() | nil,
          branches: [String.t()] | nil,
          color: Route.color()
        }

  @type icon_pill :: %{
          type: :icon,
          icon: icon(),
          route_abbrev: String.t() | nil,
          color: Route.color()
        }

  @type slashed_route_pill :: %{
          type: :slashed,
          part1: String.t(),
          part2: String.t(),
          color: Route.color()
        }

  @type audio_route :: %{
          id: Route.id(),
          route_text: String.t(),
          vehicle_type: :train | :bus | :trolley | :ferry | nil,
          track_number: pos_integer() | nil
        }

  @type icon :: :bus | :light_rail | :rail | :boat

  @cr_line_abbreviations %{
    "Fairmount" => "FMT",
    "Fitchburg" => "FBG",
    "Foxboro" => "FOX",
    "Franklin" => "FRK",
    "Greenbush" => "GRB",
    "Haverhill" => "HVL",
    "Kingston" => "KNG",
    "Lowell" => "LWL",
    "Needham" => "NDM",
    "NewBedford" => "FRV",
    "Newburyport" => "NBP",
    "Providence" => "PVD",
    "Worcester" => "WOR"
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

  # Any text longer than this max is not designed to appear correctly in our Pill Components
  @maximum_pill_text_length 3

  @spec serialize_for_departure(Route.id(), String.t(), RouteType.t(), pos_integer() | nil) :: t()
  def serialize_for_departure(route_id, route_name, route_type, track_number) do
    route =
      if route_type == :bus and String.contains?(route_name, "/") do
        [part1, part2] = String.split(route_name, "/")
        %{type: :slashed, part1: part1, part2: part2}
      else
        do_serialize(route_id, %{
          route_name: route_name,
          track_number: track_number,
          gl_branch: true
        })
      end

    Map.put(route, :color, Route.color(route_id, route_type))
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
      id: route_id,
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

  @spec serialize_route_for_alert(Route.id(), boolean()) :: t()
  def serialize_route_for_alert(route_id, gl_long \\ true) do
    route = do_serialize(route_id, %{gl_long: gl_long, gl_branch: true})

    Map.merge(route, %{color: Route.color(route_id)})
  end

  def serialize_route_for_reconstructed_alert(route_id_group, opts \\ %{})

  def serialize_route_for_reconstructed_alert({"Green", branches}, opts)
      when branches != ["Green"] do
    route = do_serialize("Green", opts)

    Map.merge(route, %{
      color: :green,
      branches: Enum.map(branches, fn "Green-" <> branch -> branch end)
    })
  end

  def serialize_route_for_reconstructed_alert({route_id, _}, opts) do
    route = do_serialize(route_id, opts)
    Map.merge(route, %{color: Route.color(route_id)})
  end

  @spec serialize_icon(Route.icon()) :: t()
  def serialize_icon(icon) do
    case icon do
      :bus ->
        %{type: :icon, icon: :bus, color: :yellow}

      :cr ->
        %{type: :icon, icon: :rail, color: :purple}

      :ferry ->
        %{type: :icon, icon: :boat, color: :teal}

      :mattapan ->
        %{type: :text, text: "M", color: :red}

      :silver ->
        %{type: :text, text: "SL", color: :silver}

      route_color ->
        pill = route_color |> to_string |> String.capitalize() |> do_serialize(%{})
        Map.merge(pill, %{color: route_color})
    end
  end

  @typep serialize_opts :: %{
           optional(:gl_branch) => boolean(),
           optional(:gl_long) => boolean(),
           optional(:route_name) => String.t(),
           optional(:track_number) => pos_integer(),
           optional(:large) => boolean()
         }

  @spec do_serialize(Route.id(), serialize_opts()) :: map()
  defp do_serialize(route_id, opts)

  defp do_serialize(route, %{large: true}),
    do: %{type: :text, text: String.upcase("#{route} line")}

  defp do_serialize("Red", _), do: %{type: :text, text: "RL"}
  defp do_serialize("Mattapan", _), do: %{type: :text, text: "M"}
  defp do_serialize("Orange", _), do: %{type: :text, text: "OL"}

  defp do_serialize("Green-" <> branch, %{gl_branch: true} = opts) do
    %{type: :text, text: if(opts[:gl_long], do: "Green Line ", else: "GL·") <> branch}
  end

  defp do_serialize("Green" <> _branch, %{gl_long: true}) do
    %{type: :text, text: "Green Line"}
  end

  defp do_serialize("Green-" <> _branch, _) do
    %{type: :text, text: "GL"}
  end

  defp do_serialize("Green", _), do: %{type: :text, text: "GL"}

  defp do_serialize("Blue", _), do: %{type: :text, text: "BL"}

  defp do_serialize("CR-" <> line, opts) do
    abbreviation =
      Map.get_lazy(@cr_line_abbreviations, line, fn ->
        Report.warning("missing_route_pill_abbreviation", line: line)
        nil
      end)

    base = %{route_abbrev: abbreviation}

    if track_number = opts[:track_number],
      do: Map.merge(base, %{type: :text, text: "TR#{track_number}"}),
      else: Map.merge(base, %{type: :icon, icon: :rail})
  end

  defp do_serialize("CapeFlyer", _), do: %{type: :icon, icon: :rail}

  defp do_serialize("Boat-" <> _line, _) do
    %{type: :icon, icon: :boat}
  end

  for {route_id, name} <- @special_bus_route_names do
    defp do_serialize(unquote(route_id), _) do
      %{type: :text, text: unquote(name)}
    end
  end

  defp do_serialize(route_id, opts) do
    # For non-special cases, prioritizes displaying the route_name and then the route_id
    # If neither are valid, then create an icon pill instead
    opts
    |> Map.get(:route_name, "")
    |> then(fn name ->
      if valid_text_for_pill?(name),
        do: name,
        else: route_id
    end)
    |> then(fn text ->
      if valid_text_for_pill?(text),
        do: %{type: :text, text: text},
        else: %{type: :icon, icon: :bus}
    end)
  end

  defp valid_text_for_pill?(text) do
    text != "" and String.length(text) <= @maximum_pill_text_length
  end
end
