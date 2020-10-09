defmodule AssemblyScriptLS.Server.Job do
  @callback perform(map()) :: Task.t()
end
