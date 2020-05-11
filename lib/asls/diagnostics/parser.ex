defmodule AssemblyScriptLS.Diagnostics.Parser do
  import NimbleParsec

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
end
