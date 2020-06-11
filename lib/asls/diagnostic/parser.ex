defmodule AssemblyScriptLS.Diagnostic.Parser do
  @moduledoc """
  The AssemblyScriptLS.Diagnostic.Parser module parses compilation diagnostics.
  The following diagnostics are supported:

  - ERROR
  - INFO
  - WARNING
  - PEDANTIC
  """
  alias AssemblyScriptLS.Diagnostic
  import NimbleParsec
  require OK

  error =
    string("ERROR")
  warning =
    string("WARNING")
  info =
    string("INFO")
  pedantic =
    string("PEDANTIC")
  inkw =
    string("in")

  digit = ?0..?9
  uppercase = ?A..?Z
  space = 32..32

  type =
    choice([error, warning, info, pedantic])
    |> lookahead(ascii_string([space], min: 1))

  code =
    ascii_string([uppercase, digit], min: 4)
    |> lookahead(string(":"))

  location =
    ignore(string("("))
    |> concat(ascii_string([digit], min: 1))
    |> ignore(string(","))
    |> concat(ascii_string([digit], min: 1))
    |> ignore(string(")"))

  defparsec :parse_diagnostic,
    type
    |> eventually(code)
    |> ignore(concat(
      string(":"),
      ascii_string([space], min: 1)
    ))
    |> concat(ascii_string([], min: 1))

  defparsec :parse_location,
    ignore(inkw)
    |> ignore(ascii_string([space], min: 1))
    |> repeat(choice([
      ascii_string([not: ?(], min: 1),
      location
    ]))

  @doc """
  Extracts compilation diagnostics from an abitrary string.
  The diagnostics are grouped by source uri.
  """
  @spec parse(String.t, String.t) :: %{String.t => [Diagnostic.t]}
  def parse(root_uri, content) do
    String.split(content, "\n")
    |> Enum.map(&String.trim/1)
    |> do_parse([], root_uri)
  end

  defp do_parse([h | t], diagnostics, root_uri) do
    cond do
      diagnostic?(h) ->
        # This will only work assuming that 
        # all diagnostics have a location(source, line and column)
        {:ok, [type, code, reason], _, _, _, _} = parse_diagnostic(h)
        {:ok, [file, line, col], rest} = location(t)
        do_parse(rest, [{type, code, reason, file, line, col} | diagnostics], root_uri)
      true ->
        do_parse(t, diagnostics, root_uri)
    end
  end

  defp do_parse([], diagnostics, root_uri) do
    Enum.reduce(diagnostics, %{}, fn {type, code, reason, file, line, col}, acc ->
      diagnostic =
        Diagnostic.new([line: line, character: col, severity: type, code: code, message: reason])
      Map.update(acc, "#{root_uri}/#{file}", [diagnostic], &([diagnostic | &1]))
    end)
  end

  defp location([h | t]) do
    if location?(h) do
      {:ok, [file, line, col], _, _, _, _} = parse_location(h)

      # --- lins and columns are zero-based
      {
        :ok, 
        [file, String.to_integer(line) - 1, String.to_integer(col) - 1],
        t
      }
    else
      location(t)
    end
  end

  defp location([]) do
    {:ok, nil, []}
  end

  defp diagnostic?("ERROR TS" <> _), do: true
  defp diagnostic?("WARNING TS" <> _), do: true
  defp diagnostic?("INFO TS" <> _), do: true
  defp diagnostic?("PEDANTIC TS" <> _), do: true
  defp diagnostic?(_), do: false

  defp location?("in " <> _), do: true
  defp location?(_), do: false
end
