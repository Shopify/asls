defmodule AssemblyScriptLS.CLI do
  @version Mix.Project.config[:version]

  alias AssemblyScriptLS.Environment

  @spec main([String.t]) :: no_return()
  def main(argv) do
    parse!(argv)
  end

  @spec start_with_options(Keyword.t) :: no_return()
  def start_with_options(opts) do
    debug? = Keyword.get(opts, :debug, false)
    level = if debug?, do: :debug, else: :error
    port = Keyword.get(opts, :port, nil)

    AssemblyScriptLS.TCP.start(port: port, debug: level)
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

  defp process({[:setup], %Optimus.ParseResult{args: args}}) do
    Environment.setup_editor(args.editor)
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
      ],
      subcommands: [
        setup: [
          name: "setup",
          about: "Setup the environment for the integration of the language server with a specific editor",
          args: [
            editor: [
              value_name: "EDITOR",
              help: "Editor to perform the setup for. The supported editors are: #{Environment.format_supported_editors()}",
              required: true,
              parser: fn(input) ->
                if Environment.supported_editor?(input) do
                  {:ok, input}
                else
                  {:error, "the supported editors are #{Environment.format_supported_editors()}"}
                end
              end
            ]
          ]
        ]
      ]
    )
  end
end
