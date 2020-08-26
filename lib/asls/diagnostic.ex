defmodule AssemblyScriptLS.Diagnostic do
  alias AssemblyScriptLS.Server

  @type t :: %__MODULE__{
    range: Range.t,
    severity: integer,
    code: String.t,
    source: String.t,
    message: String.t
  }

  @derive Jason.Encoder
  @keys [:range, :severity, :code, :source, :message]
  @enforce_keys @keys

  defstruct @keys

  defmodule Range do
    @derive Jason.Encoder
    @keys [:start, :end]
    @enforce_keys @keys

    @type t :: %__MODULE__{
      start: Position.t,
      end: Position.t
    }

    defstruct @keys
  end

  defmodule Position do
    @derive Jason.Encoder
    @keys [:line, :character]
    @enforce_keys @keys

    @type t :: %__MODULE__{
      line: integer,
      character: integer
    }

    defstruct @keys
  end

  
  def new(opts) do
    {line, rest} = Keyword.pop(opts, :line)
    {char, _rest} = Keyword.pop(rest, :character)
    position = struct!(Position, [line: line, character: char])
    range = struct!(Range, [start: position, end: position])

    struct!(__MODULE__, [
      source: Server.name,
      range: range,
      severity: severity(opts[:severity]),
      code: opts[:code],
      message: opts[:message]
    ])
  end

  defp severity("ERROR"), do: 1
  defp severity("PEDANTIC"), do: 1
  defp severity("WARNING"), do: 2
  defp severity("INFO"), do: 3
  defp severity(_), do: nil
end
