defmodule AssemblyScriptLS.CLI do
  @switches [port: :integer, help: :boolean, debug: :boolean, version: :boolean]
  @aliases [p: :port, h: :help, d: :debug, v: :version]
  @version Mix.Project.config[:version]

  def main(argv) do
    args = OptionParser.parse(argv, switches: @switches, aliases: @aliases)
    case args do
      {[help: true], _, _} ->
        help()
      {[version: true], _, _} ->
        IO.puts "v#{@version}"
      {opts, [], []} ->
        port = opts[:port]
        debug = opts[:debug]
        level = if debug, do: :debug, else: :error
        AssemblyScriptLS.TCP.start(port: port, debug: level)
      {_parsed, _args, _invalid} ->
        help()
    end
  end

  defp help do
    IO.puts """
    The AssemblyScript Language Server

    USAGE
      asls [flags]

    FLAGS
      --port      Listen for tcp on the given port
      --debug     Debug incoming and outgoing requests (devlelopment only)
      --help      Display help
      --version   Display the server version 
    """
  end
end
