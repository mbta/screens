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
    stub(@store, :fetch, fn _key -> {:error, %Nebulex.KeyError{reason: :not_found}} end)
    stub(@store, :find_node, fn _key -> {:ok, node()} end)
    stub(@store, :transaction, fn fun, _opts -> {:ok, fun.()} end)
    :ok
  end

  describe "instances/2" do
    test "retrieves cached instances for a given screen" do
      expect(@store, :fetch, fn "1" -> {:ok, [@widget]} end)

      assert Cache.instances("1", @screen) == {[@widget], %Cache.Meta{what: :hit, where: :local}}
    end

    test "generates and caches instances for a screen owned by this node" do
      expect(@store, :transaction, fn fun, [keys: ["1"]] -> {:ok, fun.()} end)
      expect(@store, :put, fn "1", [@widget], _opts -> :ok end)

      assert Cache.instances("1", @screen) == {[@widget], %Cache.Meta{what: :miss, where: :local}}
    end

    test "retrieves instances for a screen not owned by this node" do
      # The RPC path should never lock the given screen ID, otherwise a deadlock would occur when
      # the remote node tries to acquire the same lock (which would not be released until the call
      # completes, which could not happen until it acquired the lock...)
      deny(@store, :transaction, 2)
      expect(@store, :find_node, fn "1" -> {:ok, :other_node} end)

      expect(@store, :call, fn :other_node, Cache, :instances, ["1", @screen], _ ->
        # From the remote node's perspective this is a "local" key; the local node should
        # correctly tell the caller this was a remote key, leaving the "what" alone
        {[@widget], %Cache.Meta{what: {:error, :foo, @error}, where: :local}}
      end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :foo, @error}, where: :remote}}
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

    test "falls back to local generation when unable to call a remote owner node" do
      expect(@store, :find_node, fn "1" -> {:ok, :other_node} end)
      expect(@store, :call, fn :other_node, _mod, _fun, _args, _timeout -> {:error, @error} end)

      assert Cache.instances("1", @screen) ==
               {[@widget], %Cache.Meta{what: {:error, :rpc, @error}, where: :remote}}
    end

    test "raises when calling a remote owner node times out" do
      expect(@store, :find_node, fn "1" -> {:ok, :other_node} end)

      expect(@store, :call, fn :other_node, _mod, _fun, _args, _timeout ->
        {:error, %Nebulex.Error{reason: {:rpc, {:error, :timeout}}}}
      end)

      assert_raise Screens.V2.CandidateGenerator.Timeout, fn -> Cache.instances("1", @screen) end
    end
  end
end
