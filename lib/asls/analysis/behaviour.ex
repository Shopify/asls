defmodule AssemblyScriptLS.Analysis.Behaviour do
  alias AssemblyScriptLS.Runtime
  alias AssemblyScriptLS.Diagnostic

  @callback new(Runtime.t, String.t) :: Analysis.t
  @callback diagnostics(Analysis.t, [Diagnostic.t]) :: Analysis.t
  @callback cancel(Analysis.t) :: Analysis.t
  @callback running?(Analysis.t) :: boolean()
  @callback reenqueue(Analysis.t) :: Analysis.t
end
