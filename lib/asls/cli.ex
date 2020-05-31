defmodule AssemblyScriptLS.CLI do
  @switches [port: :integer, help: :boolean, debug: :boolean]
  @aliases [p: :port, h: :help, d: :debug]

  def main(argv) do
    {opts, _, _} = OptionParser.parse(argv, switches: @switches, aliases: @aliases)
      
    if opts[:help] do
      help()
    else
      port = opts[:port]
      debug = opts[:debug]
      level = if debug, do: :debug, else: :error
      AssemblyScriptLS.TCP.start(port: port, debug: level)
    end
  end

  defp help do
    IO.puts """
    The AssemblyScript Language Server

    USAGE
      asls [flags]

    FLAGS
      --port   Listen for tcp on the given port
      --help   Display help
      --debug  Debug incoming and outgoing requests (devlelopment only)
    """
  end
end
