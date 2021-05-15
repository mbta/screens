defmodule Screens.Config.Query.Opts do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  @type t :: %__MODULE__{
          include_schedules: boolean()
        }

  defstruct include_schedules: false

  use Screens.Config.Struct, with_default: true

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
