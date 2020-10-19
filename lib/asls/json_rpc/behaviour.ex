defmodule AssemblyScriptLS.JsonRpc.Behaviour do
  alias AssemblyScriptLS.JsonRpc.Message

  @type options :: Keyword.t()
  @type notification :: :error | :warning | :info | :log

  @callback start_link(options) :: GenServer.on_start
  @callback recv(Message.t(), term()) :: :ok
  @callback respond(Message.t(), term()) :: :ok
  @callback notify(notification(), String.t()) :: :ok
  @callback notify(notification(), String.t(), term()) :: :ok
  @callback notify(String.t(), map()) :: :ok
  @callback notify(String.t(), map(), term()) :: :ok
end
