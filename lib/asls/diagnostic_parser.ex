defmodule AssemblyScriptLS.DiagnosticParser do
  import NimbleParsec

  error =
    string("ERROR")
  warning =
    string("WARNING")
  info =
    string("INFO")

  code =
    ascii_string([?A..?Z, ?0..?9], min: 4)
    |> ignore(string(":"))

  type =
    choice([error, warning, info])
    |> ignore(string(" "))
    |> concat(code)
  
  reason =
    ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)

  defparsec :parse, type |> ignore(string(" ")) |> concat(reason)
end
