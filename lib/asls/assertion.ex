defmodule AssemblyScriptLS.Assertion do
  @type t :: %__MODULE__{
    contents: String.t
  }

  @keys [:contents]
  @enforce_keys @keys

  defstruct @keys

  @spec new(String.t) :: __MODULE__.t
  def new(contents) do
    struct!(__MODULE__, [
      contents: contents
    ])
  end
end
