defmodule AssemblyScriptLS.Editors.VSCodeTest do
  import Mock
  alias AssemblyScriptLS.Editors.VSCode
  use ExUnit.Case, async: false

  describe "setup/0" do
    test "returns an error when there's no package.json defined" do
      {:error, msg} = VSCode.setup()
      assert msg == """
      No package.json found. Make sure you define one and
      that you run `asls setup EDITOR` from the root of your
      project.
      """
    end

    test "doesn't update the typescript validate setting when it's set to false" do
      mocks = [
        exists?: fn _ -> true end,
        read!: fn _ -> Jason.encode!(%{"typescript.validate.enable" => false}) end
      ]

      with_mock File, [:passthrough], mocks do
        assert {:ok, :ok} == VSCode.setup()
      end
    end

    test "updates the typescript validate setting when it's set to true" do
      settings = %{"a" => 1, "typescript.validate.enable" => true}
      mocks = [
        exists?: fn _ -> true end,
        read!: fn _ -> Jason.encode!(settings) end,
        write: fn _, _ -> :ok end
      ]

      with_mock File, [:passthrough], mocks do
        assert {:ok, :ok} == VSCode.setup()
        assert_called File.write(
                        :_,
                        "{\n  \"a\": 1,\n  \"typescript.validate.enable\": false\n}"
                      )
      end
    end

    test "creates the typescript validate setting when it doesn't exist" do
      settings = %{"foo" => "bar"}
      mocks = [
        exists?: fn _ -> true end,
        read!: fn _ -> Jason.encode!(settings) end,
        write: fn _, _ -> :ok end
      ]

      with_mock File, [:passthrough], mocks do
        assert {:ok, :ok} == VSCode.setup()
        assert_called File.write(
                        :_,
                        "{\n  \"foo\": \"bar\",\n  \"typescript.validate.enable\": false\n}"
                      )
      end
    end
  end
end
