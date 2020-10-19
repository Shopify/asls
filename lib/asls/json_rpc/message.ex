defmodule AssemblyScriptLS.JsonRpc.Message do
  @derive Jason.Encoder
  @version "2.0"
  @type t :: Request.t() | Reponse.t() | Notification.t() | Unknown.t()

  defmodule Request do
    @type t :: map()
    @derive Jason.Encoder
    @keys [:jsonrpc, :id, :method, :params]
    @enforce_keys @keys

    defstruct @keys
  end

  defmodule Response do
    @type t :: map()
    @derive Jason.Encoder
    @keys [:jsonrpc, :id, :result, :error]
    @enforce_keys [:jsonrpc, :id]

    defstruct @keys
  end

  defmodule Notification do
    @type t :: map()
    @derive Jason.Encoder
    @keys [:jsonrpc, :method, :params]
    @enforce_keys @keys

    defstruct @keys
  end

  defmodule Unknown do
    @type t :: map()
    defstruct []
  end

  def from_attributes(values = %{}) do
    new(Map.merge(%{jsonrpc: @version}, values))
  end
  
  def from_attributes({type, id, payload}) when type in [:error, :result] do
    Keyword.new([{:id, id}, {type, payload}])
    |> Enum.into(%{})
    |> from_attributes
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

  def rpc_version, do: @version
end
