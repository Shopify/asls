defmodule AssemblyScriptLS.Server.Build do
  alias AssemblyScriptLS.Diagnostic
  def perform do
    case System.cmd("npm", ["run", "asbuild"], stderr_to_stdout:  true) do
      {content, 1} ->
        Diagnostic.Parser.parse(content)
      _ ->
        %{}
    end
  end
end
