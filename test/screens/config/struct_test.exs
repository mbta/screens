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

defmodule TEST.Config5 do
  @type t :: %__MODULE__{
          daughter_map: %{String.t() => TEST.Config1.t()},
          son: TEST.Config2.t()
        }

  defstruct daughter_map: %{},
            son: TEST.Config2.from_json(:default)

  use Screens.Config.Struct, children: [daughter_map: {:map, TEST.Config1}, son: TEST.Config2]
end

defmodule TEST.Config6 do
  @type t :: %__MODULE__{child: TEST.Config2.t() | nil}

  defstruct child: nil

  use Screens.Config.Struct, children: [child: TEST.Config2]

  defp value_from_json(_, nil), do: nil
end

defmodule TEST.Config7 do
  @type t :: %__MODULE__{child: TEST.Config2.t()}

  defstruct [:child]

  use Screens.Config.Struct, children: [child: TEST.Config2]
end

defmodule TEST.Config8 do
  @type t :: %__MODULE__{a: String.t() | nil}

  defstruct a: nil

  use Screens.Config.Struct
end

defmodule TEST.Config9 do
  @type t :: %__MODULE__{a: String.t() | nil, b: boolean()}

  defstruct a: nil,
            b: false

  use Screens.Config.Struct

  defp value_from_json("a", value), do: value
  defp value_to_json(:a, value), do: value
end

defmodule Screens.Config.StructTest do
  use ExUnit.Case, async: true

  alias TEST.{Config1, Config2, Config3, Config4, Config5, Config6, Config7, Config8, Config9}

  describe "__using__/1" do
    test "generates a functioning config module when passed default options" do
      original_json = %{"action" => "exclude", "values" => ["a", "b"], "unsupported_key" => "foo"}
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

    test "supports generating functions for map-valued child config fields" do
      original_json = %{
        "daughter_map" => %{
          "1" => %{"action" => "include", "values" => ["e", "f"]},
          "2" => %{"action" => "exclude", "values" => ["g"]}
        }
      }

      config = %Config5{
        daughter_map: %{
          "1" => %Config1{action: :include, values: ["e", "f"]},
          "2" => %Config1{action: :exclude, values: ["g"]}
        },
        son: %Config2{action: :include, values: []}
      }

      assert config == Config5.from_json(original_json)
    end

    test "defers to the using module for handling (or not handling) nil-valued children" do
      assert %Config6{child: nil} == Config6.from_json(%{"child" => nil})

      assert_raise RuntimeError,
                   "Elixir.TEST.Config7.value_from_json/2 not implemented (key: `child`)",
                   fn -> Config7.from_json(%{"child" => nil}) end
    end

    test "defers to the using module for handling (or not handling) fields not defined in `children` list" do
      original_json1 = %{"a" => "foo"}

      assert_raise RuntimeError,
                   "Elixir.TEST.Config8.value_from_json/2 not implemented (key: `a`)",
                   fn -> Config8.from_json(original_json1) end

      config = %Config9{a: "foo", b: false}

      assert config == Config9.from_json(original_json1)

      original_json2 = %{"a" => "foo", "b" => true}

      assert_raise FunctionClauseError, fn -> Config9.from_json(original_json2) end
    end
  end
end
