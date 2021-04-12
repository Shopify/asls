defmodule AssemblyScriptLS.Runtime.Behaviour do
  @callback ensure(String.t) :: {:ok, Runtime.t} | {:error, String.t}
end
