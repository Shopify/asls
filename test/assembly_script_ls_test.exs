defmodule AssemblyScriptLSTest do
  use ExUnit.Case
  doctest AssemblyScriptLS

  test "greets the world" do
    assert AssemblyScriptLS.hello() == :world
  end
end
