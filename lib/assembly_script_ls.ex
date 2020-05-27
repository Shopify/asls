defmodule AssemblyScriptLS do
  def start(socket) do
    socket
    |> children
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  defp children(socket)do
    [
      {AssemblyScriptLS.JsonRpc, [socket: socket]}
    ]
  end
end

