defmodule Screens.SignsUiConfig.State.LocalFetch do
  @moduledoc false

  alias Screens.SignsUiConfig.State
  @behaviour Screens.ConfigCache.State.Fetch

  @impl true
  def fetch_config(current_version) do
    with {:ok, file_contents} <- File.read(local_config_path()),
         {:ok, decoded} <- Jason.decode(file_contents) do
      {:ok, State.Parse.parse_config(decoded), current_version}
    else
      _ -> :error
    end
  end

  defp local_config_path do
    case Application.get_env(:screens, :local_signs_ui_config_file_spec) do
      {:priv, file_name} -> Path.join(:code.priv_dir(:screens), file_name)
      {:test, file_name} -> Path.join(~w[#{File.cwd!()} test fixtures #{file_name}])
    end
  end
end
