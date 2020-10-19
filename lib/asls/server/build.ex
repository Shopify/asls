defmodule AssemblyScriptLS.Server.Build do
  @behaviour AssemblyScriptLS.Server.Job
  alias AssemblyScriptLS.Diagnostic
  require Logger

  @impl true
  def perform(params) do
    uri = params[:root_uri]
    task = Task.async(fn -> build(uri) end)
    Logger.debug("Starting build: #{inspect(task.ref)}")
    task
  end

  defp build(uri) do
    case System.cmd("npm", ["run", "asbuild"], stderr_to_stdout:  true) do
      {content, 1} ->
        Diagnostic.Parser.parse(uri, content)
      _ ->
        %{}
    end
  end
end
