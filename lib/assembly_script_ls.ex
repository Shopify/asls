defmodule AssemblyScriptLS do
  require Logger

  def start(socket, debug) do
    result =
      socket
      |> children
      |> Supervisor.start_link(strategy: :one_for_one)

    Application.ensure_all_started(:asls)

    Logger.configure(level: debug)

    result
  end

  defp children(socket)do
    [
      {AssemblyScriptLS.Server, []},
      {
        AssemblyScriptLS.JsonRpc, [
          socket: socket,
          transport: AssemblyScriptLS.TCP
        ],
      }
    ]
  end
end

