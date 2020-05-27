defmodule AssemblyScriptLS.CLI do
  @switches [port: :integer]
  @aliases [p: :port]

  def main(argv) do
    case OptionParser.parse(argv, switches: @switches, aliases: @aliases) do
      {[port: port], [], []} ->
        AssemblyScriptLS.TCP.start(port: port)
      _ ->
        help()
    end
  end

  defp help do
    IO.puts """
    The AssemblyScript Language Server

    USAGE
      asls [flags]

    FLAGS
      --port    Listen for tcp on the given port
    """
  end
end
