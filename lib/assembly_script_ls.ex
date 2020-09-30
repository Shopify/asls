defmodule AssemblyScriptLS do
  require OK
  require Logger

  def start(socket, debug) do
    OK.try do
      _ <- Supervisor.start_link(children(socket), strategy: :one_for_one)
      _ <- Application.ensure_all_started(:asls)
    after
      Logger.configure(level: debug)
      OK.success(socket)
    rescue
      trace ->
        OK.failure(~s(
          Could not start the language server supervision tree.
          Reason: #{trace}
        ))
    end
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

