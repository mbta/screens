defmodule Screens.Schedules.Fetch do
  @moduledoc """
  Acquires and parses schedules for an explicit service date.

  This module owns the schedule request's relationships and departure filtering.
  It does not select the current service date or manage a parsed schedule store.
  Requests bypass response-body caching; parsed data is cached by the store.
  """

  alias Screens.Schedules.Schedule
  alias Screens.V2.Departure
  alias Screens.V3Api

  @includes ~w[route.line stop trip.route_pattern.representative_trip trip.stops]

  @spec fetch(Departure.params(), Date.t()) :: Schedule.result()
  @spec fetch(Departure.params(), Date.t(), (String.t(), map() -> term())) ::
          Schedule.result()
  def fetch(%{} = params, %Date{} = service_date, get_json_fn \\ &V3Api.get_json_uncached/2) do
    request = fn path, encoded, _validator ->
      case get_json_fn.(path, encoded) do
        {:ok, body} -> {:ok, body, nil}
        result -> result
      end
    end

    case acquire(params, service_date, nil, request) do
      {:ok, schedules, _validator} -> {:ok, schedules}
      _ -> :error
    end
  end

  @doc "Acquires all pages, or revalidates a previously loaded single-page dataset."
  def acquire(
        params,
        %Date{} = service_date,
        last_modified \\ nil,
        get_json_fn \\ &V3Api.get_json_uncached/3
      ) do
    encoded_params =
      params
      |> Map.put(:date, service_date)
      |> Map.put(:include, @includes)
      |> Departure.encode_params()

    pages(encoded_params, last_modified, get_json_fn, %{}, [], [])
  rescue
    error ->
      Logster.warning(event: "schedule_acquisition_error", error_type: inspect(error.__struct__))
      :error
  end

  defp pages(params, validator, request, seen, data, included) do
    if Map.has_key?(seen, params) or map_size(seen) >= 1_000 do
      :error
    else
      case request.("schedules", params, validator) do
        {:ok, %{"data" => page_data} = body, modified} when is_list(page_data) ->
          data = data ++ page_data
          included = included ++ Map.get(body, "included", [])

          case get_in(body, ["links", "next"]) do
            nil ->
              schedules = V3Api.Parser.parse(%{"data" => data, "included" => included})
              # A response validator is not a dataset-wide version. Revalidate
              # multi-page datasets by reacquiring all pages instead.
              modified = if map_size(seen) == 0, do: modified, else: nil
              {:ok, Enum.reject(schedules, &is_nil(&1.departure_time)), modified}

            next when is_binary(next) ->
              next_params = next |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
              # Never follow the link's host or forward credentials to it.
              # Only pagination controls may change the original acquisition scope.
              pagination =
                Map.filter(next_params, fn {key, _} -> String.starts_with?(key, "page[") end)

              pages(
                Map.merge(params, pagination),
                nil,
                request,
                Map.put(seen, params, true),
                data,
                included
              )

            _ ->
              :error
          end

        :not_modified when not is_nil(validator) and data == [] ->
          :not_modified

        _ ->
          :error
      end
    end
  end
end
