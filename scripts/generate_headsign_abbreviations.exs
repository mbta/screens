# To run this file, create an updated CSV of headsign abbreviations.
# Format the CSV with the base headsign as column 0, and any abbreviations as columns 1+.
# Example Run:
# elixir scripts/generate_headsign_abbreviations.exs --input "priv/local/abbreviations.csv"
# elixir scripts/generate_headsign_abbreviations.exs --input "priv/local/abbreviations.csv" --output abbreviations.exs

{[input: input, output: output], _, _} =
  System.argv()
  |> OptionParser.parse(strict: [input: :string, output: :string])

if input == nil do
  IO.puts(
    "Usage: elixir scripts/generate_headsign_abbreviations.exs --input <input_csv> --output <output_file>"
  )

  System.halt(1)
end

output_path =
  case output do
    nil -> Path.join("priv/local", "headsign_abbreviations.exs")
    _ -> Path.join("priv/local", output)
  end

abbreviations =
  File.read!(input)
  |> String.split("\n", trim: true)
  |> Enum.map(fn row ->
    [base_headsign | abbreviations] = String.split(row, ",")
    {base_headsign, abbreviations |> Enum.uniq() |> Enum.reject(&(&1 == "" or &1 == "?"))}
  end)
  |> Enum.into(%{})

File.write(
  output_path,
  inspect(abbreviations, limit: :infinity, pretty: true, custom_options: [sort_maps: true])
)
