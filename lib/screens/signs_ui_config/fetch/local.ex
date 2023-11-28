defmodule Screens.SignsUiConfig.Fetch.Local do
  @behaviour Screens.SignsUiConfig.Fetch

  @impl true
  def fetch_config(current_version) do
    case File.read(local_config_path()) do
      {:ok, contents} -> {:ok, contents, current_version}
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
