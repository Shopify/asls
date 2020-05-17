defmodule AssemblyScriptLS.Server do
  use GenServer

  @impl GenServer
  def init(_) do
    {:ok, {}}
  end
end
