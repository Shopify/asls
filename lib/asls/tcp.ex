defmodule AssemblyScriptLS.TCP do
  @moduledoc """
  The AssemblyScriptLS.TCP module is a wrapper around TCP connections.

  It is in charge of:
    - Starting a tcp connection in a given port
    - Listening for incoming packets
    - Starting the language server supervision tree
  """

  alias AssemblyScriptLS.JsonRpc
  alias AssemblyScriptLS.JsonRpc.Message
  require OK
  require Logger

  @opts [:binary, packet: :line, active: false, reuseaddr: true]
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
    port = Keyword.get(opts, :port) || @port
    debug = Keyword.get(opts, :debug)
    OK.try do
      socket <- :gen_tcp.listen(port, @opts)
      socket <- :gen_tcp.accept(socket)
      _ <- AssemblyScriptLS.start(socket, debug)
    after
      Logger.debug("Server listening in port #{port}")
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
    body = Jason.encode!(packet) <> "\r\n\r\n"
    header = "Content-Length: #{byte_size(body)}\r\n\r\n"

    Logger.debug("Outgoing message: \r\n #{inspect(header)} \r\n #{inspect(body)}")

    :gen_tcp.send(socket, header <> body)
  end

  defp recv(socket) do
    OK.try do
      socket <- set_packet_type(socket, :line)
      header <- :gen_tcp.recv(socket, 0)
      length <- content_length(header)
      socket <- set_packet_type(socket, :raw)
      # TODO: Fix the hardcoded byte count
      _ <- :gen_tcp.recv(socket, 2)
      payload <- :gen_tcp.recv(socket, length)
      json <- Jason.decode(payload, [keys: :atoms])
    after
      Logger.debug("Incoming message: \r\n #{inspect(json)}")
      JsonRpc.recv(Message.new(json))
      recv(socket)
    rescue
      # Ignore everything if the first line
      # is not a valid header
      :invalid_header ->
        IO.inspect "Invalid header"
        recv(socket)

      # Ignore invalid json payloads
      %Jason.DecodeError{} ->
        recv(socket)
      error ->
        OK.failure(error)
    end
  end

  defp content_length(<<"Content-Length: ", length :: binary>>) do
    length
    |> String.trim
    |> String.to_integer
    |> OK.success
  end

  defp content_length(_) do
    OK.failure(:invalid_header)
  end

  defp set_packet_type(socket, type) do
    case :inet.setopts(socket, packet: type) do
      :ok ->
        OK.success(socket)
      {:error, reason} ->
        OK.failure(reason)
    end
  end
end
