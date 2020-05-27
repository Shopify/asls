defmodule AssemblyScriptLS.JsonRpc do
  @state %{socket: nil}

  alias AssemblyScriptLS.TCP
  use GenServer

  # --- Client API

  def start_link(opts) do
    socket = opts[:socket]
    GenServer.start_link(__MODULE__,%{@state | socket: socket}, name: __MODULE__)
  end

  def recv(packet) do
    send(packet)
  end

  def send(packet) do
    GenServer.call(__MODULE__, {:send, packet})
  end

  # --- Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:send, packet}, _from, state = %{socket: socket}) do
    TCP.send(socket, packet)
    {:reply, :ok, state}
  end
end
