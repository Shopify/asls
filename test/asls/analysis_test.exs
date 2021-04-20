defmodule AssemblyScriptLS.AnalysisTest do
  alias AssemblyScriptLS.Runtime
  alias AssemblyScriptLS.Analysis

  use ExUnit.Case, async: true

  setup _ do
    Process.flag(:trap_exit, true)

    rt = %Runtime{
      root_uri: "./",
      executable: "cli",
      target: "debug",
    }
    id = "foo/bar.ts"
    analysis = Analysis.new(rt, id)

    [analysis: analysis, rt: rt, id: id]
  end

  describe "new/2" do
    test "creates a new analysis and enqueues a new task", %{analysis: analysis, rt: rt, id: id} do
      assert analysis.runtime == rt
      assert analysis.id == id
      assert analysis.diagnostics == []
      assert analysis.task.ref
    end
  end

  describe "diagnostics/1" do
    test "sets the diagnostics for an analysis", %{analysis: analysis} do
      analysis = Analysis.diagnostics(analysis, [1])
      assert length(analysis.diagnostics) == 1
    end
  end

  describe "assertions" do
    test "sets the assertions for an analysis", %{analysis: analysis} do
      analysis = Analysis.assertions(analysis, [1])
      assert length(analysis.assertions) == 1
    end
  end

  describe "cancel/1" do
    test "calls Task.shutdown/2 on the analysis task", %{analysis: analysis} do
      Process.monitor(analysis.task.pid)
      Analysis.cancel(analysis)
      assert_receive {:DOWN, _, _, _, :shutdown}
    end
  end

  describe "running?/1" do
    test "returns true if the process is alive", %{analysis: analysis} do
      assert Analysis.running?(analysis)
    end

    test "returns false if the process is not alive", %{analysis: analysis} do
      running? =
        Analysis.cancel(analysis)
        |> Analysis.running?

      refute running?
    end
  end

  describe "reenqueue/1" do
    test "cancels the current task and starts a new one", %{analysis: analysis} do
      current_ref = analysis.task.ref
      analysis = Analysis.reenqueue(analysis)
      new_ref = analysis.task.ref
      assert current_ref != new_ref
    end
  end
end
