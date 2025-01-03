#!/usr/bin/env -S ERL_FLAGS=+B elixir

# Script used to format the spreadsheet found at
# https://docs.google.com/spreadsheets/d/1lHogme-2SuDSgjrRK52k7yVgSFK-v_LMmUfkYgBJjIU/edit?gid=179933470#gid=179933470

# To use this script:
# 1. Download the spreadsheet above to a temporary directory
# 2. Run `elixir scripts/format_elevator_data.exs --path <path_to_csv>`

Mix.install([{:jason, "~> 1.4"}, {:csv, "~> 3.2"}])

{[path: path], _, _} =
  System.argv()
  |> OptionParser.parse(strict: [path: :string])

formatted_data =
  path
  |> File.stream!()
  |> CSV.decode(headers: true)
  |> Enum.map(fn
    {:ok, %{"elevator_id" => ""}} ->
      nil

    {:ok,
     %{
       "elevator_id" => id,
       "alternate_elevator_ids" => alternate,
       "Exiting System Categorization" => category,
       "Short Text" => summary
     }} ->
      alternate_ids =
        case String.split(alternate, ~r/(\s|,)+/) do
          [""] -> []
          ids -> ids
        end

      redundancy =
        case Integer.parse(category) do
          {integer, _rest} -> integer
          :error -> nil
        end

      {id, %{alternate_ids: alternate_ids, redundancy: redundancy, summary: summary}}
  end)
  |> Enum.reject(&is_nil/1)
  |> Map.new()

File.write("priv/elevators.json", Jason.encode!(formatted_data, pretty: true))
