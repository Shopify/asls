defmodule AssemblyScriptLS.TCP do
  @moduledoc """
  The AssemblyScriptLS.TCP module is a wrapper around TCP connections.

  It is in charge of:
    - Starting a tcp connection in a given port
    - Listening for incoming packets
    - Starting the language server supervision tree
  """

  alias AssemblyScriptLS.JsonRpc
  require OK

  @opts [:binary, packet: 0, active: false, reuseaddr: true]
  @port 7658

  @type socket :: port
  @type packet :: iodata

  @doc """
  Listens for a tcp connection in a given port and
  starts the language server supervision tree.

  Returns `{:error, reason}` if the socket connection
  could not be established.
  """
  def start(opts \\ []) do
    port = Keyword.get(opts, :port, @port)
    OK.try do
      socket <- :gen_tcp.listen(port, @opts)
      socket <- :gen_tcp.accept(socket)
      _ <- AssemblyScriptLS.start(socket)
    after
      recv(socket)
    rescue
      error ->
        OK.failure(error)
    end
  end

  @doc """
  Sends a packet on a given socket. 

  Returns `:ok | {:error, reason}`
  """
  @spec send(socket, packet) :: :ok | {:error, term}
  def send(socket, packet) do
    :gen_tcp.send(socket, packet)
  end

  defp recv(socket) do
    OK.try do
      msg <- :gen_tcp.recv(socket, 0)
    after
      JsonRpc.recv(msg)
      recv(socket)
    rescue
      error ->
        OK.failure(error)
    end
  end
end
