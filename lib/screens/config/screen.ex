defmodule Screens.Config.Screen do
  alias Screens.Config.{Bus, Gl, Solari}

  @type t :: %__MODULE__{
          vendor: :gds | :mercury | :solari,
          device_id: String.t(),
          name: String.t(),
          app_id: :bus_eink | :gl_eink_single | :gl_eink_double | :solari,
          last_refresh_timestamp: DateTime.t() | nil,
          disabled: boolean(),
          app_params: Bus.t() | Gl.t() | Solari.t(),
          tags: list(String.t())
        }

  @default_vendor :solari
  @default_device_id ""
  @default_name ""
  @default_app_id :solari
  @default_last_refresh_timestamp nil
  @default_disabled false
  @default_app_params_module Solari

  @app_config_modules_by_app_id %{
    bus_eink: Bus,
    gl_eink_single: Gl,
    gl_eink_double: Gl,
    solari: Solari
  }

  defstruct vendor: @default_vendor,
            device_id: @default_device_id,
            name: @default_name,
            app_id: @default_app_id,
            last_refresh_timestamp: @default_last_refresh_timestamp,
            disabled: @default_disabled,
            app_params: @default_app_params_module.from_json(:default),
            tags: []

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    vendor = Map.get(json, "vendor", :default)
    device_id = Map.get(json, "device_id", :default)
    name = Map.get(json, "name", :default)
    app_id = Map.get(json, "app_id", :default)
    last_refresh_timestamp = Map.get(json, "last_refresh_timestamp", :default)
    disabled = Map.get(json, "disabled", :default)
    app_params = Map.get(json, "app_params", :default)
    tags = Map.get(json, "tags", :default)

    %__MODULE__{
      vendor: vendor_from_json(vendor),
      device_id: device_id,
      name: name,
      app_id: app_id_from_json(app_id),
      last_refresh_timestamp: last_refresh_timestamp_from_json(last_refresh_timestamp),
      disabled: disabled,
      app_params: app_params_from_json(app_params, app_id),
      tags: tags
    }
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{
        vendor: vendor,
        device_id: device_id,
        name: name,
        app_id: app_id,
        last_refresh_timestamp: last_refresh_timestamp,
        disabled: disabled,
        app_params: app_params,
        tags: tags
      }) do
    %{
      "vendor" => vendor_to_json(vendor),
      "device_id" => device_id,
      "name" => name,
      "app_id" => app_id_to_json(app_id),
      "last_refresh_timestamp" => last_refresh_timestamp_to_json(last_refresh_timestamp),
      "disabled" => disabled,
      "app_params" => app_params_to_json(app_params, app_id),
      "tags" => tags
    }
  end

  for vendor <- ~w[gds mercury solari]a do
    vendor_string = Atom.to_string(vendor)

    defp vendor_from_json(unquote(vendor_string)) do
      unquote(vendor)
    end

    defp vendor_to_json(unquote(vendor)) do
      unquote(vendor_string)
    end
  end

  defp vendor_from_json(_) do
    @default_vendor
  end

  for app_id <- ~w[bus_eink gl_eink_single gl_eink_double solari]a do
    app_id_string = Atom.to_string(app_id)

    defp app_id_from_json(unquote(app_id_string)) do
      unquote(app_id)
    end

    defp app_id_to_json(unquote(app_id)) do
      unquote(app_id_string)
    end

    defp app_params_from_json(app_params, unquote(app_id_string)) do
      @app_config_modules_by_app_id[unquote(app_id)].from_json(app_params)
    end

    defp app_params_to_json(app_params, unquote(app_id)) do
      @app_config_modules_by_app_id[unquote(app_id)].to_json(app_params)
    end
  end

  defp app_id_from_json(_) do
    @default_app_id
  end

  defp app_params_from_json(_, _) do
    @default_app_params_module.from_json(:default)
  end

  defp last_refresh_timestamp_from_json(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> dt
      {:error, _} -> last_refresh_timestamp_from_json(:default)
    end
  end

  defp last_refresh_timestamp_from_json(_) do
    @default_last_refresh_timestamp
  end

  defp last_refresh_timestamp_to_json(nil) do
    nil
  end

  defp last_refresh_timestamp_to_json(dt) do
    DateTime.to_iso8601(dt)
  end
end
