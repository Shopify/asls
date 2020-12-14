defmodule AssemblyScriptLS.EnvironmentTest do
  use ExUnit.Case
  import Mock

  alias AssemblyScriptLS.Environment
  alias AssemblyScriptLS.Editors.VSCode

  describe "supported_editors/0" do
    test "returns the list of supported editors" do
      assert ["vscode"] == Environment.supported_editors()
    end
  end

  describe "supported_editor?/1" do
    test "verifies if the given editor is supported" do
      assert Environment.supported_editor?("vscode")
      assert Environment.supported_editor?("VSCode")
      refute Environment.supported_editor?("emacs")
    end
  end

  describe "setup_editor/1" do
    test "calls the setup function of a supported editor" do
      with_mock VSCode, [setup: fn -> {:ok, :ok} end] do
        Environment.setup_editor("vscode")
        assert_called VSCode.setup
      end
    end
  end
end
