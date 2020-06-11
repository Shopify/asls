defmodule AssemblyScriptLS.JsonRpc.Message do
  @version "2.0"
  @derive Jason.Encoder

  defmodule Request do
    @derive Jason.Encoder
    @keys [:jsonrpc, :id, :method, :params]
    @enforce_keys @keys

    defstruct @keys
  end

  defmodule Response do
    @derive Jason.Encoder
    @keys [:jsonrpc, :id, :result, :error]
    @enforce_keys [:jsonrpc, :id]

    defstruct @keys
  end

  defmodule Notification do
    @derive Jason.Encoder
    @keys [:jsonrpc, :method, :params]
    @enforce_keys @keys

    defstruct @keys
  end

  defmodule Unknown do
    defstruct []
  end

  def from_attributes(values = %{}) do
    new(Map.merge(%{jsonrpc: @version}, values))
  end

  def new(%{jsonrpc: _v, id: _id, method: _method, params: _params} = values) do
    struct(Request, values)
  end

  def new(%{jsonrpc: _v, id: _id, result: _result, error: _error} = values) do
    struct(Response, values)
  end

  def new(%{jsonrpc: _v, id: _id, result: _result} = values) do
    struct(Response, values)
  end

  def new(%{jsonrpc: _v, id: _id, error: _error} = values) do
    struct(Response, values)
  end

  def new(%{jsonrpc: _v, method: _method, params: _params} = values) do
    struct(Notification, values)
  end

  def new(_) do
    struct(Unknown, [])
  end
end
