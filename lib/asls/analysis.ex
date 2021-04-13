# Assume that an analysis can only be
# a diagnostic analysis. We'll have to amend
# this once we have other types of analysis like
# go-to definition or autocompletion.

defmodule AssemblyScriptLS.Analysis do
  alias AssemblyScriptLS.Runtime
  alias AssemblyScriptLS.Diagnostic

  @behaviour AssemblyScriptLS.Analysis.Behaviour

  require Logger

  @type t :: %__MODULE__{
    id: String.t,
    runtime: Runtime.t,
    task: Task.t,
    diagnostics: [Diagnostic.t]
  }
  @required_keys [:runtime, :id, :diagnostics]
  @enforce_keys @required_keys

  defstruct [:runtime, :id, :diagnostics, :task]

  def new(runtime, id) do
    task = perform(runtime, id)
    struct!(__MODULE__, [
      runtime: runtime,
      id: id,
      task: task,
      diagnostics: []
    ])
  end

  def diagnostics(analysis = %__MODULE__{}, diagnostics) do
    %{analysis | diagnostics: diagnostics}
  end

  def cancel(analysis = %__MODULE__{}) do
    Task.shutdown(analysis.task, :infinity)
    analysis
  end

  def running?(analysis = %__MODULE__{}) do
    Process.alive?(analysis.task.pid)
  end

  def reenqueue(analysis = %__MODULE__{}) do
    target = if running?(analysis), do: cancel(analysis), else: analysis

    %{target | task: perform(target.runtime, target.id)}
  end

  defp perform(rt, id) do
    # Add a task supervisor
    task = Task.async(fn -> build(rt, id) end)
    Logger.debug("Starting build: #{inspect(task.ref)}")
    task
  end

  defp build(rt, id) do
    %Runtime{executable: exec, target: target} = rt
    path = path_from_uri(id)

    case System.cmd(exec, [path, "--#{target}", "--noEmit"], stderr_to_stdout:  true) do
      {content, 1} ->
        Diagnostic.Parser.parse(id, content)
      _ ->
        {id, []}
    end
  end

  defp path_from_uri(uri) do
    URI.decode(URI.parse(uri).path)
  end
end

