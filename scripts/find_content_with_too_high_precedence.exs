# Script to perform dirty checking of a screens configuration file.
# Used to find cases where evergreen content may have a higher priority than an alert, which may
# prevent it from being rendered on a screen.
#
# The output will be in CSV form, written to STDOUT.
#
# This script's output may lead to false positives - verify the output before performing any
# changes to a screen configuration file.

# Example usages:
# elixir scripts/find_content_with_too_high_precedence.exs
# elixir scripts/find_content_with_too_high_precedence.exs --config <path_to_config_to_validate>

Mix.install([{:jason, "~> 1.4"}])

{opts, _, _} =
  System.argv()
  |> OptionParser.parse(strict: [config: :string])

config_file = Keyword.get(opts, :config, "./priv/local.json")

defmodule ValidateConfig do
  # This guard makes assumptions about the returned values from
  # `lib/screens/v2/widget_instance/alert.ex#priority/1`
  defguard is_too_high_priority(val) when is_list(val) and val in [[0], [1], [0, 1], [1, 0]]

  def find_evergreen_with_too_high_priority(config_file) do
    with {:ok, body} <- File.read(config_file),
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      IO.puts("Sign_ID,Asset_Path")

      Enum.map(json.screens, &evergreen_with_high_priorities/1)
      |> Enum.filter(fn content -> length(content) != 0 end)
      |> List.flatten()
      |> Enum.sort()
      |> Enum.each(&IO.puts("#{elem(&1, 0)},#{elem(&1, 1)}"))
    else
      {:error, reason} -> IO.puts("Unable to parse input file '#{config_file}' - #{reason}")
      _ -> IO.puts("An unknown error occurred while parsing the input file")
    end
  end

  def evergreen_with_high_priorities(
        {screen_id, %{app_params: %{evergreen_content: all_evergreen_content}}}
      ) do
    all_evergreen_content
    |> Enum.filter(&too_high_priorities/1)
    |> Enum.map(fn evergreen_content -> {screen_id, evergreen_content.asset_path} end)
  end

  def evergreen_with_high_priorities(_), do: []

  def too_high_priorities(%{priority: priorities}) when is_too_high_priority(priorities), do: true
  def too_high_priorities(_), do: false
end

ValidateConfig.find_evergreen_with_too_high_priority(config_file)
