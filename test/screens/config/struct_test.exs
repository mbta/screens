defmodule TEST.Config1 do
  @type t :: %__MODULE__{
          action: :include | :exclude,
          values: list(String.t())
        }

  @enforce_keys [:action, :values]
  defstruct @enforce_keys

  use Screens.Config.Struct

  defp value_from_json("action", "include"), do: :include
  defp value_from_json("action", "exclude"), do: :exclude

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end

defmodule TEST.Config2 do
  @type t :: %__MODULE__{
          action: :include | :exclude,
          values: list(String.t())
        }

  defstruct action: :include,
            values: []

  use Screens.Config.Struct, with_default: true

  defp value_from_json("action", "include"), do: :include
  defp value_from_json("action", "exclude"), do: :exclude

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end

defmodule TEST.Config3 do
  @type t :: %__MODULE__{
          daughter: TEST.Config1.t(),
          son: TEST.Config2.t()
        }

  @enforce_keys [:daughter]
  defstruct daughter: nil,
            son: TEST.Config2.from_json(:default)

  use Screens.Config.Struct, children: [daughter: TEST.Config1, son: TEST.Config2]
end

defmodule TEST.Config4 do
  @type t :: %__MODULE__{
          daughter: TEST.Config1.t(),
          sons: list(TEST.Config2.t())
        }

  @enforce_keys [:daughter]
  defstruct daughter: nil,
            sons: []

  use Screens.Config.Struct, children: [daughter: TEST.Config1, sons: {:list, TEST.Config2}]
end

defmodule Screens.Config.StructTest do
  use ExUnit.Case, async: true

  alias TEST.{Config1, Config2, Config3, Config4}

  describe "__using__/1" do
    test "generates a functioning config module when passed default options" do
      original_json = %{"action" => "exclude", "values" => ["a", "b"]}
      config = %Config1{action: :exclude, values: ["a", "b"]}
      serialized_config = %{action: :exclude, values: ["a", "b"]}

      assert config == Config1.from_json(original_json)
      assert serialized_config == Config1.to_json(config)
    end

    test "includes handling of :default when directed to do so" do
      expected_config = %Config2{action: :include, values: []}

      assert expected_config == Config2.from_json(:default)
    end

    test "does not include handling of :default when not directed to do so" do
      assert_raise FunctionClauseError, fn -> Config1.from_json(:default) end
    end

    test "generates value_from_json/2, value_to_json/2 for child config fields" do
      original_json = %{"daughter" => %{"action" => "include", "values" => ["c"]}}

      config = %Config3{
        daughter: %Config1{action: :include, values: ["c"]},
        son: %Config2{action: :include, values: []}
      }

      assert config == Config3.from_json(original_json)
    end

    test "supports generating functions for list-valued child config fields" do
      original_json = %{
        "daughter" => %{"action" => "include", "values" => ["d"]},
        "sons" => [%{"values" => ["e", "f"]}, %{"action" => "exclude", "values" => ["g"]}]
      }

      config = %Config4{
        daughter: %Config1{action: :include, values: ["d"]},
        sons: [
          %Config2{action: :include, values: ["e", "f"]},
          %Config2{action: :exclude, values: ["g"]}
        ]
      }

      assert config == Config4.from_json(original_json)
    end

    test "fails if the using module doesn't provide `children` and doesn't define value_from_json/2, value_to_json/2" do
      assert_raise ArgumentError, fn ->
        defmodule TEST.InvalidConfig do
          @type t :: %__MODULE__{
                  action: :include | :exclude,
                  values: list(String.t())
                }

          @enforce_keys [:action, :values]
          defstruct @enforce_keys

          use Screens.Config.Struct
        end
      end
    end
  end
end
