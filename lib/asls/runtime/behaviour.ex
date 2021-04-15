defmodule AssemblyScriptLS.Runtime.Behaviour do
  alias AssemblyScriptLS.Runtime
  @callback ensure(String.t) :: {:ok, Runtime.t} | {:error, String.t}
  @callback to_string(Runtime.t) :: String.t
end
