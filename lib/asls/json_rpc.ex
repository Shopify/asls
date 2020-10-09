defmodule AssemblyScriptLS.JsonRpc do
  @moduledoc """
  The AssemblyScriptLS.JsonRpc module implements the JSON RPC protocol.
  It is the layer between the transport layer (TCP) and the Language Server
  Specification layer.
  """
  @behaviour AssemblyScriptLS.JsonRpc.Behaviour
  @state %{socket: nil, transport: nil}
  use GenServer
  use OK.Pipe

  alias AssemblyScriptLS.Server
  alias AssemblyScriptLS.JsonRpc.Message
  alias AssemblyScriptLS.JsonRpc.Message.{
    Request,
    Notification,
    Response,
    Unknown
  }

  # --- Client API

  @impl true
  def start_link(opts \\ []) do
    socket = opts[:socket]
    transport = opts[:transport]
    name = Keyword.get(opts, :name, __MODULE__)

    state = %{@state | socket: socket, transport: transport}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def recv(message, name \\ __MODULE__) do
    GenServer.call(name, {:recv, message})
  end

  @impl true
  def respond({_type, _id, _payload} = opts, name \\ __MODULE__) do
    snd(Message.from_attributes(opts), name)
  end

  @impl true
  def notify(x, y, name \\ __MODULE__)

  @impl true
  def notify(type, message, name) when type in [:error, :warning, :info, :log] do
    params = %{type: type, message: message}
    opts = %{method: "window/showMessage", params: params}
    snd(Message.from_attributes(opts), name)
  end

  @impl true
  def notify(method, params, name) do
    snd(Message.from_attributes(%{method: method, params: params}), name)
  end

  defp snd(message, name) do
    GenServer.call(name, {:send, message})
  end

  # --- Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:send, message}, _from, state) do
    :ok = send_through_transport(message, state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Request{} = req}, _from, state) do
    message = 
      Server.handle_request(req)
      ~>> Message.from_attributes

    :ok = send_through_transport(message, state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Notification{} = notification}, _from, state) do
    Server.handle_notification(notification)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Response{} = _response}, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Unknown{}}, _from, state) do
    {:reply, :ok, state}
  end

  #TODO: Handle info
  
  # --- Helpers
  
  defp send_through_transport(message, %{socket: socket, transport: transport}) do
    transport.send(socket, message)
  end
end
