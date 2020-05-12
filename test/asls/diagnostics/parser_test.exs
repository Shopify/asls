defmodule AssemblyScriptLS.Diagnostics.ParserTest do
  alias AssemblyScriptLS.Diagnostics.Parser

  use ExUnit.Case, async: true

  test "parses ERROR diagnostics" do
    error = "ERROR TS1126: Unexpected end of text."
    {:ok, [type, code, reason], _, _, _, _} = Parser.parse_diagnostic(error)

    assert type == "ERROR"
    assert code == "TS1126"
    assert reason == "Unexpected end of text."
  end

  test "parses error location" do
    location = "in file.ts(1,12)"
    {:ok, [file, line, col], _, _, _, _} = Parser.parse_location(location)

    assert file == "file.ts"
    assert line == "1"
    assert col == "12"
  end
end
