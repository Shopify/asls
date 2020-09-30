defmodule AssemblyScriptLS.TCP do
  @moduledoc """
  The AssemblyScriptLS.TCP module is a wrapper around TCP connections.

  It is in charge of:
    - Starting a tcp connection in a given port
    - Listening for incoming packets
    - Starting the language server supervision tree
  """

  alias AssemblyScriptLS.JsonRpc, as: RPC
  alias AssemblyScriptLS.JsonRpc.Message
  require OK
  use OK.Pipe
  require Logger

  @opts [:binary, packet: :line, active: false, reuseaddr: true]
  @port 7658

  @type socket :: port
  @type packet :: iodata

  @doc """
  Listens for a tcp connection in a given port and
  starts the language server supervision tree.

  If an error occurs, it gets logged to stderr
  """
  @spec start(Keyword.t()) :: no_return()
  def start(opts \\ []) do
    port = opts[:port] || @port
    debug = opts[:debug]
    result = run(port, debug, @opts)

    if OK.failure?(result) do
      {:error, reason} = result
      IO.puts(:stderr, reason)
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

  defp run(port, debug_level, connection_opts) do
    listen(port, connection_opts)
    ~>> accept
    ~>> AssemblyScriptLS.start(debug_level)
    ~>> recv
  end

  defp listen(port, opts) do
    OK.try do
      socket <- :gen_tcp.listen(port, opts)
      verified <- :inet.port(socket)
    after
      IO.puts(~s(Server listening @ #{verified}))
      OK.success(socket)
    rescue
      e ->
        OK.failure(~s(
          Error occurred while listening to connections.
          Error: #{inspect(e)}
        ))
    end
  end

  defp accept(socket) do
    result = :gen_tcp.accept(socket)
    if OK.failure?(result) do
      {:error, e} = result
      OK.failure(~s(
        Error occurred while accepting connections.
        Error: #{inspect(e)}
      ))
    else
      result
    end
  end

  defp recv(socket) do
    OK.try do
      socket <- set_packet_type(socket, :line)
      header <- :gen_tcp.recv(socket, 0)
      length <- content_length(header)
      socket <- set_packet_type(socket, :raw)
      payload <- :gen_tcp.recv(socket, length + 2) # -- 2 is due to spaces
      json <- Jason.decode(payload, [keys: :atoms])
    after
      Logger.debug("Incoming message: \r\n #{inspect(json)}")
      RPC.recv(Message.new(json))
      recv(socket)
    rescue
      #  -- Ignore everything if the first line is not a valid header
      :invalid_header ->
        recv(socket)
      # -- Ignore invalid json payloads
      %Jason.DecodeError{} ->
        recv(socket)
      error ->
        OK.failure(~s(
          Error occurred while handling an incoming message.
          Error: #{inspect(error)}
        ))
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
      error ->
        OK.wrap(error)
    end
  end
end
