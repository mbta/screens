# To run this file, create an updated CSV of headsign abbreviations.
# Format the CSV with the base headsign as column 0, and any abbreviations as columns 1+.
# Output will be written to priv/local/ directory, with a default file name of headsign_abbreviations.exs
# Example Runs:
# elixir scripts/generate_headsign_abbreviations.exs --input priv/local/abbreviations.csv
# elixir scripts/generate_headsign_abbreviations.exs --input priv/local/abbreviations.csv --output abbreviations.exs

{opts, _, _} =
  System.argv()
  |> OptionParser.parse(strict: [input: :string, output: :string])

input = Keyword.get(opts, :input, nil)
output_filename = Keyword.get(opts, :output, "headsign_abbreviations.exs")

if input == nil do
  IO.puts(
    "Usage: elixir scripts/generate_headsign_abbreviations.exs --input <input_csv> --output <output_file>"
  )

  System.halt(1)
end

abbreviations =
  File.read!(input)
  |> String.split("\n", trim: true)
  |> Enum.map(fn row ->
    [base_headsign | abbreviations] = String.split(row, ",")
    {base_headsign, abbreviations |> Enum.uniq() |> Enum.reject(&(&1 == "" or &1 == "?"))}
  end)
  |> Enum.reject(fn {base_headsign, abbreviations} -> abbreviations == [base_headsign] end)
  |> Enum.into(%{})

File.write(
  Path.join("priv/local", output_filename),
  inspect(abbreviations, limit: :infinity, pretty: true, custom_options: [sort_maps: true])
)
