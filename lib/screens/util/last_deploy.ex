defmodule Screens.Util.LastDeployTime do
  @moduledoc false

  @bucket "mbta-screens"

  def get_last_deploy_time do
    env = Application.get_env(:screens, :environment_name, "screens-prod")
    path = "/#{env}/LAST_DEPLOY"

    get_operation = ExAws.S3.get_object(@bucket, path)

    case ExAws.request(get_operation) do
      {:ok, %{last_modified: last_modified}} ->
        last_modified

      {:error, _} ->
        nil
    end
  end
end
