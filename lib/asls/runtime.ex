defmodule AssemblyScriptLS.Runtime do
  require OK
  use OK.Pipe

  @asc_paths %{local: "./node_modules/.bin/asc", global: "asc"}
  @config_file_path "./asconfig.json"
  @target "asls"

  # The runtime consists of the original uri
  # and the executable used.
  def ensure(uri) do
    root(uri)
    ~>> configuration
    ~>> target
    ~>> executable
  end

  defp root(uri) do
    decoded = URI.decode(URI.parse(uri).path)
    case File.cd(decoded) do
      :ok ->
        OK.success(decoded)
      _ ->
        OK.failure("The project root is invalid or doesn't exist.")
    end
  end

  defp executable(_) do
    cond do
      File.exists?(@asc_paths.local) ->
        OK.success(nil)
      true ->
        {_, exit} = System.cmd("which", [@asc_paths.global])
        if exit == 0 do
          OK.success(nil)
        else
          OK.failure("No executable for AssemblyScript found.")
        end
    end
  end

  defp configuration(_) do
    contents = File.read(@config_file_path) 
    if OK.failure?(contents) do
      OK.failure("No #{@config_file_path} file found.")
    else
      contents
    end
  end

  defp target(contents) do
    result = Jason.decode(contents)
    
    if OK.failure?(result) do
      OK.failure("Invalid #{@config_file_path} file.")
    else
      {:ok, payload} = result
      if payload[:targets][String.to_atom(@target)] do
        OK.success(nil)
      else
        OK.failure(~s(
          Your asconfig.json file should include a target named asls:

          {
            ...
            targets: {
              asls: {}
            }
            ...
          }
        ))
      end
    end
  end
end
