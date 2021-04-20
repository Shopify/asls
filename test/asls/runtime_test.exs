defmodule AssemblyScriptLS.RuntimeTest do
  alias AssemblyScriptLS.Runtime
  use ExUnit.Case, async: false
  import Mock
  @valid_config_file %{
    targets: %{
      debug: %{}
    }
  }

  describe "ensure/1" do
    test "returns an error message when the root directory doesn't exist" do
      {:error, msg} = Runtime.ensure "non-existent"
      assert msg == "The project root is invalid or doesn't exist."
    end
    
    test "default asconfig? false and release target when the configuration file is not found" do
      exists = fn
          "./node_modules/.bin/asc" -> true
        _ -> false
      end

      with_mock File, [:passthrough], [cd: fn _ -> :ok end, exists?: exists] do
        {:ok, rt} = Runtime.ensure "root"
        refute rt.asconfig?
        assert rt.target == "release"
      end
    end

    test "returns an error message when the configuration file is invalid" do
      with_mock File, [cd: fn _ -> :ok end, exists?: fn _ -> true end, read!: fn _ -> "" end] do
        {:error, reason} = Runtime.ensure "root"
        assert reason == "Invalid asconfig.json file."
      end
    end

    test "returns an error message when the configuration file doesn't contain a target" do
      with_mock File, [cd: fn _ -> :ok end, exists?: fn _ -> true end, read!: fn _ -> "{}" end] do
        {:error, reason} = Runtime.ensure "root"
        assert String.trim(reason) == String.trim(~s(
          Your asconfig.json file should include at least one target definition.
        ))
      end
    end

    test "returns an error message when no assemblyscript executable is found" do
      exists = fn
        "./node_modules/.bin/asc" -> false
        _ -> true
      end

      file = {File, [:passthrough], [cd: fn _ -> :ok end, exists?: exists, read!: fn _ -> Jason.encode!(@valid_config_file) end]}
      system = {System, [], [cmd: fn _, _ ->  {0, 1} end]}

      with_mocks([file, system]) do
        {:error, reason} = Runtime.ensure "root"
        assert String.trim(reason) == String.trim(~s(
          No executable for AssemblyScript found.
        ))
      end
    end

    test "returns an env with the global assemblyscript installation when no local one is found" do
      exists = fn
          "./node_modules/.bin/asc" -> false
        _ -> true
      end

      file = {File, [:passthrough], [cd: fn _ -> :ok end, exists?: exists, read!: fn _ -> Jason.encode!(@valid_config_file) end]}
      system = {System, [], [cmd: fn _, _ ->  {0, 0} end]}

      with_mocks([file, system]) do
        {:ok, env} = Runtime.ensure "root"
        assert env.executable == "asc"
        assert env.target == "debug"
        assert env.root_uri == "root"
      end
    end

    test "returns an env with the local assemblyscript installation" do
      exists = fn _-> true end

      file = {File, [:passthrough], [cd: fn _ -> :ok end, exists?: exists, read!: fn _ -> Jason.encode!(@valid_config_file) end]}

      with_mocks([file]) do
        {:ok, env} = Runtime.ensure "root"
        assert String.contains?(env.executable, "/node_modules/.bin/asc")
        assert env.target == "debug"
        assert env.root_uri == "root"
      end
    end
  end

  describe "to_string/1" do
    test "returns a string representation of the given runtime struct" do
      exists = fn _-> true end
      file = {File, [:passthrough], [cd: fn _ -> :ok end, exists?: exists, read!: fn _ -> Jason.encode!(@valid_config_file) end]}

      with_mocks([file]) do
        {:ok, env} = Runtime.ensure "root"
        expected = """
        Project root: root;
        AssemblyScript compiler: #{env.executable};
        Compilation target: #{env.target};
        """
        assert expected == Runtime.to_string(env)
      end
    end
  end
end
