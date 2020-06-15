defmodule AssemblyScriptLS.Server.Build do
  alias AssemblyScriptLS.Diagnostic
  require Logger

  def perform(root_uri) do
    task = Task.async(fn -> build(root_uri) end)
    Logger.debug("Starting build: #{inspect(task.ref)}")
    task
  end

  defp build(root_uri) do
    case System.cmd("npm", ["run", "asbuild"], stderr_to_stdout:  true) do
      {content, 1} ->
        Diagnostic.Parser.parse(root_uri, content)
      _ ->
        %{}
    end
  end
end
