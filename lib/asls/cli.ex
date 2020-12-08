defmodule AssemblyScriptLS.CLI do
  @version Mix.Project.config[:version]

  def main(argv) do
    parse!(argv)
  end

  defp parse!(argv) do
    result = Optimus.parse!(config(), argv)
    process(result)
  end

  defp process(result = %Optimus.ParseResult{}) do
    port = result.options.port
    level = if result.flags.debug, do: :debug, else: :error
    AssemblyScriptLS.TCP.start(port: port, debug: level)
  end

  defp config do
    Optimus.new!(
      name: "asls",
      version: "v#{@version}",
      allow_unknown_args: false,
      parse_double_dash: true,
      flags: [
        debug: [
          short: "-d",
          long: "--debug",
          help: "Debug incoming and outgoing requests (Development only)",
          multiple: false,
          required: false
        ],
      ],
      options: [
        port: [
          value_name: "PORT",
          short: "-p",
          long: "--port",
          help: "Listen for tcp connections in the given port",
          required: false,
          parser: :integer
        ],
      ]
    )
  end
end
