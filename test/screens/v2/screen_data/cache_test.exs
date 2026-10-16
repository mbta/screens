defmodule Screens.V2.ScreenData.CacheTest do
  use ExUnit.Case, async: true

  alias Screens.TestSupport.CandidateGeneratorStub, as: Stub
  alias Screens.V2.ScreenData.Cache
  alias Screens.V2.WidgetInstance.Placeholder
  alias ScreensConfig.Screen

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @parameters injected(Screens.V2.ScreenData.Parameters)
  @store injected(Cache.Store)

  @error %Nebulex.Error{reason: :timeout}
  @screen %Screen{app_id: :test_app, app_params: %{}, device_id: "", name: "", vendor: ""}
  @widget %Placeholder{color: :red, slot_names: [:main]}

  require Stub
  Stub.candidate_generator(TestGenerator, fn _ -> [placeholder(:red)] end)

  setup do
    stub(@parameters, :candidate_generator, fn %Screen{app_id: :test_app} -> TestGenerator end)
    stub(@parameters, :seconds_until_refresh, fn _screen_id, :test_app, _now -> 1 end)
    stub(@store, :fetch, fn _key -> {:error, %Nebulex.KeyError{reason: :not_found}} end)
    stub(@store, :find_node, fn _key -> {:ok, node()} end)
    stub(@store, :transaction, fn fun, _opts -> {:ok, fun.()} end)
    :ok
  end

  @now ~U[2026-01-01 00:00:00Z]

  describe "instances/2" do
    test "retrieves cached instances for a given screen" do
      expect(@store, :fetch, fn "1" -> {:ok, [@widget]} end)
      expect(@parameters, :seconds_until_refresh, fn "1", :test_app, @now -> 10 end)

      assert Cache.instances("1", @screen, now_fn: fn -> @now end) ==
               {[@widget], %Cache.Meta{what: :hit, where: :local, ttl: 10}}
    end

    test "generates and caches instances for a screen owned by this node" do
      expect(@store, :transaction, fn fun, [keys: ["1"]] -> {:ok, fun.()} end)
      expect(@parameters, :seconds_until_refresh, fn "1", :test_app, @now -> 10 end)
      expect(@store, :put, fn "1", [@widget], ttl: 9_500 -> :ok end)

      assert Cache.instances("1", @screen, now_fn: fn -> @now end) ==
               {[@widget], %Cache.Meta{what: :miss, where: :local, ttl: 10}}
    end

    test "retrieves instances for a screen not owned by this node" do
      # The RPC path should never lock the given screen ID, otherwise a deadlock would occur when
      # the remote node tries to acquire the same lock (which would not be released until the call
      # completes, which could not happen until it acquired the lock...)
      deny(@store, :transaction, 2)
      expect(@store, :find_node, fn "1" -> {:ok, :other_node} end)
      now = ~U[2026-01-01 12:34:56Z]

      expect(@store, :call, fn :other_node, Cache, :instances, ["1", @screen, opts], _timeout ->
        # Ensure options were forwarded
        assert opts[:now_fn].() == now
        # From the remote node's perspective this is a "local" key; the local node should
        # correctly tell the caller this was a remote key, leaving the "what" alone
        {:ok, {[@widget], %Cache.Meta{what: {:error, :foo, @error}, where: :local, ttl: 10}}}
      end)

      assert Cache.instances("1", @screen, now_fn: fn -> now end) ==
               {[@widget], %Cache.Meta{what: {:error, :foo, @error}, where: :remote, ttl: 10}}
    end

    test "falls back to local generation when unable to find the owner node" do
      expect(@store, :find_node, fn "1" -> {:error, @error} end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :find_node, @error}, where: :local}}
    end

    test "generates instances anyway when unable to open a transaction" do
      expect(@store, :transaction, fn _fun, [keys: ["1"]] -> {:error, @error} end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :transaction, @error}, where: :local}}
    end

    test "falls back to local generation when unable to fetch the key" do
      expect(@store, :fetch, fn "1" -> {:error, @error} end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :fetch, @error}, where: :local}}
    end

    test "tolerates an error storing the generated instances" do
      expect(@store, :put, fn "1", [@widget], _opts -> {:error, @error} end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :put, @error}, where: :local}}
    end

    test "falls back to local generation when unable to connect to a remote owner node" do
      expect(@store, :find_node, fn "1" -> {:ok, :other_node} end)
      expect(@store, :call, fn :other_node, _, _, _, _ -> {:error, {:erpc, :noconnection}} end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :rpc_connect, nil}, where: :local}}
    end

    test "raises when calling a remote owner node times out" do
      expect(@store, :find_node, fn "1" -> {:ok, :other_node} end)
      expect(@store, :call, fn :other_node, _, _, _, _ -> {:error, {:erpc, :timeout}} end)

      assert_raise Screens.V2.CandidateGenerator.Timeout, fn -> Cache.instances("1", @screen) end
    end
  end
end
