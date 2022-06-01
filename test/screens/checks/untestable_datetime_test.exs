defmodule Screens.Checks.UntestableDateTimeTest do
  use Credo.Test.Case

  alias Screens.Checks.UntestableDateTime

  test "it should not report 'now' function calls used as default values in a function's parameters" do
    ~S"""
    defmodule MyTestableCode do
      @type t :: %__MODULE__{
        value: integer()
      }

      @enforce_keys [:value]
      defstruct @enforce_keys

      def get_current_value(t, utc_now \\ Time.utc_now())

      def get_current_value(%__MODULE__{value: value} = t, utc_now)
        when is_integer(value)
        when is_struct(utc_now)  do
        if utc_now.hour < 12, do: morning(value, utc_now), else: evening(t.value, utc_now)
      end

      def get_current_value(_t, _utc_now), do: nil

      defp morning(value, utc_now) do
        if utc_now.minute == 0, do: value + 1, else: value - 1
      end

      defp evening(value, utc_now) do
        if utc_now.minute == 0, do: value, else: -value
      end
    end
    """
    |> to_source_file()
    |> run_check(UntestableDateTime)
    |> refute_issues()
  end

  test "it should report 'now' function calls within function body" do
    ~S"""
    defmodule MyUntestableCode do
      @type t :: %__MODULE__{
        value: integer()
      }

      @enforce_keys [:value]
      defstruct @enforce_keys

      def get_current_value(%__MODULE__{value: value} = t) when is_integer(value) do
        utc_now = Time.utc_now()
        if utc_now.hour < 12, do: morning(value), else: evening(t.value)
      end

      def get_current_value(_t), do: nil

      def extremely_untestable_function do
        now1 = DateTime.utc_now()
        {:ok, now2} = DateTime.now("Etc/UTC")
        now3 = DateTime.now!("Etc/UTC")
        now4 = Date.utc_today()
        now5 = NaiveDateTime.local_now()
        now6 = NaiveDateTime.utc_now()
        now7 = Time.utc_now()

        [now1, now2, now3, now4, now5, now6, now7]
      rescue
        exception ->
          IO.inspect(DateTime.utc_now())
          reraise(exception)
      catch
        thrown_value ->
          IO.puts("#{thrown_value} was thrown at #{DateTime.utc_now()}")
      after
        IO.puts("One more DateTime for good measure: #{DateTime.utc_now()}")
      else
        list_of_datetimes ->
          IO.puts("A big list of datetimes was returned by this function at #{DateTime.utc_now()}!")
          list_of_datetimes
      end

      defp morning(value) do
        utc_now = DateTime.utc_now()
        if utc_now.minute == 0, do: value + 1, else: value - 1
      end

      defp evening(value) do
        utc_now = DateTime.utc_now()
        if utc_now.minute == 0, do: value, else: -value
      end
    end
    """
    |> to_source_file()
    |> run_check(UntestableDateTime)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 14

      expected_trigger_counts = %{
        "Time.utc_now/0" => 2,
        "Date.utc_today/0" => 1,
        "DateTime.now!/1" => 1,
        "DateTime.now/1" => 1,
        "DateTime.utc_now/0" => 7,
        "NaiveDateTime.local_now/0" => 1,
        "NaiveDateTime.utc_now/0" => 1
      }

      trigger_counts =
        issues
        |> Enum.map(& &1.trigger)
        |> Enum.frequencies()

      assert expected_trigger_counts == trigger_counts
    end)
  end
end
