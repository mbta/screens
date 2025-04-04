defmodule Screens.V3Api.Parser do
  @moduledoc "Tools for parsing V3 API responses."

  @parsers %{
    "alert" => Screens.Alerts.Parser,
    "facility" => Screens.Facilities.Parser,
    "line" => Screens.Lines.Parser,
    "prediction" => Screens.Predictions.Parser,
    "route" => Screens.Routes.Parser,
    "route_pattern" => Screens.RoutePatterns.Parser,
    "schedule" => Screens.Schedules.Parser,
    "stop" => Screens.Stops.Parser,
    "trip" => Screens.Trips.Parser,
    "vehicle" => Screens.Vehicles.Parser
  }

  @typep included :: %{{id :: String.t(), type :: String.t()} => object()}
  @typep object :: %{String.t() => term()}

  @doc "Parse a complete JSON-decoded V3 API response."
  @spec parse(response :: object()) :: struct() | [struct()]
  def parse(%{"data" => data} = response) when is_map(data) do
    [resource] = parse(%{response | "data" => [data]})
    resource
  end

  def parse(%{"data" => data} = response) when is_list(data) do
    included =
      response
      |> Map.get("included", [])
      |> then(&Enum.concat(data, &1))
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    Enum.map(data, &parse_resource(&1, included))
  end

  @doc """
  Parse a single resource. Expects as the second argument a map of all resources that were present
  in the response, keyed by ID and type, for resolving relationship references.
  """
  @spec parse_resource(object(), included()) :: struct()
  for {type, module} <- @parsers do
    def parse_resource(%{"type" => unquote(type)} = data, included),
      do: unquote(module).parse(data, included)
  end

  @doc """
  Convenience for looking up a relationship and parsing the referenced resource(s). Expects an
  `included` map of the same kind as `parse_resource/2` does. If any referenced resources are not
  present, returns `default`.
  """
  @spec included(relationship :: object(), included(), any()) :: any()
  def included(
        %{"data" => [%{"id" => first_id, "type" => first_type} | _]} = data,
        included,
        default
      ) do
    # Assuming a "many" relationship is either completely loaded or not, look at the first
    # reference to determine whether it is.
    case Map.get(included, {first_id, first_type}) do
      nil -> default
      _resource -> included!(data, included)
    end
  end

  def included(%{"data" => %{"id" => id, "type" => type}}, included, default) do
    case Map.get(included, {id, type}) do
      nil -> default
      resource -> parse_resource(resource, included)
    end
  end

  def included(%{"data" => []}, _included, _default), do: []
  def included(%{"data" => nil}, _included, _default), do: nil

  @doc "As `included/3` but asserts that any referenced resources are present."
  @spec included!(relationship :: object(), included()) :: struct() | [struct()] | nil
  def included!(%{"data" => references}, included) when is_list(references) do
    Enum.map(references, fn %{"id" => id, "type" => type} ->
      included |> Map.fetch!({id, type}) |> parse_resource(included)
    end)
  end

  def included!(%{"data" => reference}, included) when is_map(reference) do
    [resource] = included!(%{"data" => [reference]}, included)
    resource
  end

  def included!(%{"data" => nil}, _included), do: nil
end
