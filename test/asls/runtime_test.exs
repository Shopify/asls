defmodule AssemblyScriptLS.RuntimeTest do
  alias AssemblyScriptLS.Runtime
  use ExUnit.Case, async: true

  describe "ensure/1" do
    test "returns an error message when the root directory doesn't exist" do
      {:error, msg} = Runtime.ensure "non-existent"
      assert msg == "The project root is invalid or doesn't exist."
    end
  end

  # defp create_file(path) do
    # :ok = File.mkdir_p(path)
  # end
end
