# Script used to get the amount of time trains take to go leave one platform and arrive at the next.
# Only works with the Orange Line.
# Take 5 arguments: --start-date, --end-date, --start-time, --end-time, --direction_id
# start_date and end_date are used to get the relevant data from https://dashboard-api.labs.transitmatters.org/api/traveltimes
# start_time and end_time are used to filter down the data to just the time range provided. Both times are expected to be in ISO 8601 format.
# direction_id can be 0 (southbound) or 1 (northbound)

# Example usage: elixir scripts/travel_times.exs --start-date 2023-07-01 --end-date 2023-07-07 --start-time 12:00:00Z --end-time 21:00:00Z --direction-id 0

Mix.install([
  {:httpoison, "~> 1.8.0"},
  {:jason, "~> 1.4.0"}
])

{opts, _, _} =
  System.argv()
  |> OptionParser.parse(
    strict: [
      start_date: :string,
      end_date: :string,
      start_time: :string,
      end_time: :string,
      direction_id: :integer
    ]
  )

{:ok, start_date} = opts |> Keyword.get(:start_date) |> Date.from_iso8601()
{:ok, end_date} = opts |> Keyword.get(:end_date) |> Date.from_iso8601()
start_time = opts |> Keyword.get(:start_time) |> Time.from_iso8601!()
end_time = opts |> Keyword.get(:end_time) |> Time.from_iso8601!()
direction_id = Keyword.get(opts, :direction_id)

get_times = fn [prev, next] ->
  response_data =
    Range.new(0, Date.diff(end_date, start_date))
    |> Enum.flat_map(fn index ->
      IO.write(".")
      query_date = Date.add(start_date, index)

      case HTTPoison.get(
             "https://dashboard-api.labs.transitmatters.org/api/traveltimes/#{query_date}?from_stop=#{prev}&to_stop=#{next}"
           ) do
        {:ok, %{body: data}} ->
          data

        {:error, error} ->
          IO.inspect(error)
      end
      |> Jason.decode!(keys: :atoms)
    end)

  percentages =
    if response_data == [] do
      %{}
    else
      times =
        response_data
        |> Enum.filter(fn row ->
          {:ok, converted_dt, _} = DateTime.from_iso8601("#{row.dep_dt}-04:00")

          Time.compare(start_time, converted_dt) in [:lt, :eq] and
            Time.compare(end_time, converted_dt) in [:gt, :eq]
        end)
        |> Enum.map(& &1.travel_time_sec)

      number_under_30 = times |> Enum.filter(&(&1 < 30)) |> length()
      percent_under_30 = number_under_30 / length(times)

      number_under_60 = times |> Enum.filter(&(&1 >= 30 and &1 < 60)) |> length()
      percent_under_60 = number_under_60 / length(times)

      number_over_60 = times |> Enum.filter(&(&1 >= 60)) |> length()
      percent_over_60 = number_over_60 / length(times)

      %{
        under_30: percent_under_30 * 100.0,
        under_60: percent_under_60 * 100.0,
        over_60: percent_over_60 * 100.0
      }
    end

  [next, percentages]
end

sb_platform_pairs = [
  ["70036", "70034"],
  ["70034", "70032"],
  ["70032", "70278"],
  ["70278", "70030"],
  ["70030", "70028"],
  ["70028", "70026"],
  ["70026", "70024"],
  ["70024", "70022"],
  ["70022", "70020"],
  ["70020", "70018"],
  ["70018", "70016"],
  ["70016", "70012"],
  ["70012", "70010"],
  ["70010", "70008"],
  ["70008", "70006"],
  ["70006", "70004"],
  ["70004", "70002"]
]

nb_platform_pairs = [
  ["70001", "70003"],
  ["70003", "70005"],
  ["70005", "70007"],
  ["70007", "70009"],
  ["70009", "70011"],
  ["70011", "70013"],
  ["70013", "70015"],
  ["70015", "70017"],
  ["70017", "70019"],
  ["70019", "70021"],
  ["70021", "70023"],
  ["70023", "70025"],
  ["70025", "70027"],
  ["70027", "70029"],
  ["70029", "70031"],
  ["70031", "70279"],
  ["70279", "70033"],
  ["70033", "70035"]
]

if direction_id == 0 do
  sb_content =
    sb_platform_pairs
    |> Enum.map(&get_times.(&1))

  File.write!("scripts/southbound_times.json", Jason.encode!(sb_content), [:binary])
else
  nb_content =
    nb_platform_pairs
    |> Enum.map(&get_times.(&1))

  File.write!("scripts/northbound_times.json", Jason.encode!(nb_content), [:binary])
end
