defmodule AssemblyScriptLS.JsonRpc.Message do
  defmodule Request do
    @derive Jason.Encoder
    defstruct [:jsonrpc, :id, :method, :params]
  end

  defmodule Response do
    @derive Jason.Encoder
    defstruct [:jsonrpc, :id, :result, :error]
  end

  defmodule Notification do
    @derive Jason.Encoder
    defstruct [:jsonrpc, :method, :params]
  end

  defmodule Unknown do
    defstruct []
  end


  def new(%{jsonrpc: _v, id: _id, method: _method, params: _params} = values) do
    struct(Request, Enum.into(values, []))
  end

  def new(%{jsonrpc: _v, id: _id, result: _result, error: _error} = values) do
    struct(Response, Enum.into(values, []))
  end

  def new(%{jsonrpc: _v, method: _method, params: _params} = values) do
    struct(Notification, Enum.into(values, []))
  end

  def new(_) do
    struct(Unknown, [])
  end
end
