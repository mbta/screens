defmodule Screens.Config.Screen do
  @moduledoc false

  alias Screens.Config.{Bus, BusShelter, Dup, Gl, Solari, V2}
  alias Screens.Util

  @type t :: %__MODULE__{
          vendor: :gds | :mercury | :solari | :c3ms | :outfront | :lg_mri,
          device_id: String.t(),
          name: String.t(),
          app_id:
            :bus_eink
            | :bus_eink_v2
            | :bus_shelter
            | :bus_shelter_v2
            | :dup
            | :dup_v2
            | :gl_eink_single
            | :gl_eink_double
            | :gl_eink_v2
            | :solari
            | :solari_v2
            | :solari_large
            | :solari_large_v2,
          refresh_if_loaded_before: DateTime.t() | nil,
          disabled: boolean(),
          app_params: Bus.t() | BusShelter.t() | Dup.t() | Gl.t() | Solari.t(),
          tags: list(String.t())
        }

  @recognized_app_ids ~w[bus_eink bus_shelter dup gl_eink_single gl_eink_double solari solari_large]a
  @recognized_v2_app_ids ~w[bus_eink_v2 bus_shelter_v2 dup_v2 gl_eink_v2 solari_v2 solari_large_v2]a
  @recognized_app_id_strings Enum.map(
                               @recognized_app_ids ++ @recognized_v2_app_ids,
                               &Atom.to_string/1
                             )

  @app_config_modules_by_app_id %{
    bus_eink: Bus,
    bus_eink_v2: V2.BusEink,
    bus_shelter: BusShelter,
    bus_shelter_v2: V2.BusShelter,
    dup: Dup,
    dup_v2: V2.Dup,
    gl_eink_single: Gl,
    gl_eink_double: Gl,
    gl_eink_v2: V2.GlEink,
    solari: Solari,
    solari_v2: V2.Solari,
    solari_large: Solari,
    solari_large_v2: V2.SolariLarge
  }

  @enforce_keys [:vendor, :device_id, :name, :app_id, :app_params]
  defstruct vendor: nil,
            device_id: nil,
            name: nil,
            app_id: nil,
            refresh_if_loaded_before: nil,
            disabled: false,
            app_params: nil,
            tags: []

  @spec from_json(map()) :: t() | nil
  def from_json(%{"app_id" => app_id} = json) when app_id in @recognized_app_id_strings do
    app_id = String.to_existing_atom(app_id)

    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} ->
        {String.to_existing_atom(k), value_from_json(k, v, app_id)}
      end)

    struct!(__MODULE__, struct_map)
  end

  # Prevents the application from breaking if we introduce a new app_id
  def from_json(_), do: nil

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{app_id: app_id} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v, app_id)} end)
  end

  @spec schedule_refresh_at_time(t(), DateTime.t()) :: t()
  def schedule_refresh_at_time(screen_config, time) do
    %__MODULE__{screen_config | refresh_if_loaded_before: time}
  end

  for vendor <- ~w[gds mercury solari c3ms outfront]a do
    vendor_string = Atom.to_string(vendor)

    defp value_from_json("vendor", unquote(vendor_string), _app_id) do
      unquote(vendor)
    end
  end

  defp value_from_json("app_id", _app_id_string, app_id), do: app_id

  defp value_from_json("refresh_if_loaded_before", timestamp, _app_id)
       when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> dt
      {:error, _} -> nil
    end
  end

  defp value_from_json("app_params", app_params, app_id) do
    @app_config_modules_by_app_id[app_id].from_json(app_params)
  end

  defp value_from_json(_, value, _), do: value

  defp value_to_json(:refresh_if_loaded_before, %DateTime{} = dt, _app_id) do
    DateTime.to_iso8601(dt)
  end

  defp value_to_json(:app_params, app_params, app_id) do
    @app_config_modules_by_app_id[app_id].to_json(app_params)
  end

  defp value_to_json(_, value, _), do: value
end
