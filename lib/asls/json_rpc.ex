defmodule AssemblyScriptLS.JsonRpc do
  @state %{socket: nil, transport: nil}

  alias AssemblyScriptLS.Server
  alias AssemblyScriptLS.JsonRpc.Message.{
    Request,
    Response,
    Notification,
    Unknown
  }

  use GenServer

  # --- Client API

  # TODO: fix name
  def start_link(opts \\ []) do
    socket = opts[:socket]
    transport = opts[:transport]
    name = Keyword.get(opts, :name, __MODULE__)

    state = %{@state | socket: socket, transport: transport}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def recv(message) do
    GenServer.call(__MODULE__, {:recv, message})
  end

  def send(message) do
    GenServer.call(__MODULE__, {:send, message})
  end

  def respond(id, result, :result) do
    opts = [jsonrpc: "2.0", id: id, result: result]
    response = struct(Response, opts)
    send(response)
  end

  def respond(id, error, :error) do

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
