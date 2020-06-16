defmodule AssemblyScriptLS.JsonRpc do
  @moduledoc """
  The AssemblyScriptLS.JsonRpc module implements the JSON RPC protocol.
  It is the layer between the transport layer (TCP) and the Language Server
  Specification layer.
  """
  @state %{socket: nil, transport: nil}
  use GenServer

  alias AssemblyScriptLS.Server
  alias AssemblyScriptLS.JsonRpc.Message
  alias AssemblyScriptLS.JsonRpc.Message.{
    Request,
    Notification,
    Response,
    Unknown
  }

  # --- Client API

  def start_link(opts \\ []) do
    socket = opts[:socket]
    transport = opts[:transport]
    name = Keyword.get(opts, :name, __MODULE__)

    state = %{@state | socket: socket, transport: transport}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def recv(message, name \\ __MODULE__) do
    GenServer.call(__MODULE__, {:recv, message})
  end

  def send(message, name \\ __MODULE__) do
    GenServer.call(__MODULE__, {:send, message})
  end

  def respond(type, id, payload) when type in [:error, :result] do
    opts =
      Keyword.new([{:id, id}, {type, payload}])
      |> Enum.into(%{})

    send(Message.from_attributes(opts))
  end

  def notify(type, message) when type in [:error, :warning, :info, :log] do
    params = %{type: type, message: message}
    opts = %{method: "window/showMessage", params: params}
    send(Message.from_attributes(opts))
  end

  def notify(method, params) do
    send(Message.from_attributes(%{method: method, params: params}))
  end

  # --- Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:send, message}, _from, state = %{transport: transport, socket: socket}) do
    :ok = transport.send(socket, message)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Request{} = req}, _from, state) do
    Server.handle_request(req)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Notification{} = notification}, _from, state) do
    Server.handle_notification(notification)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Response{} = response}, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:recv, %Unknown{}}, _from, state) do
    {:reply, :ok, state}
  end

  #TODO: Handle info
end
