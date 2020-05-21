defmodule AssemblyScriptLS.TCP do
  use GenServer

  @state %{socket: nil, port: nil}
  @opts [:binary, packet: 0, active: true, reuseaddr: true]
  @port 7658

  def start_link(port \\ @port) do
    GenServer.start_link(__MODULE__, %{@state | port: port}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    with {:ok, socket} <- :gen_tcp.listen(state[:port], @opts),
         {:ok, socket} <- :gen_tcp.accept(socket) do
      {:ok, %{state | socket: socket}}
    else
      {:error, any} ->
        IO.inspect any
    end
  end

  @impl true
  def handle_info({:tcp, _socket, msg}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
