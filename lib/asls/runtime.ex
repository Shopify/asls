defmodule AssemblyScriptLS.Runtime do
  require OK
  use OK.Pipe

  @behaviour AssemblyScriptLS.Runtime.Behaviour

  @asc_paths %{local: "./node_modules/.bin/asc", global: "asc"}
  @config_file_path "asconfig.json"
  @type t :: %__MODULE__{
    root_uri: String.t,
    executable: String.t,
    target: String.t,
    asconfig?: boolean(),
  }
   
  defstruct [:root_uri, :executable, :target, :asconfig?]

  @doc """
  Ensures the runtime requirements of the language server
  """
  @spec ensure(String.t) :: {:ok, __MODULE__.t()} | {:error, String.t}
  def ensure(uri) do
    OK.wrap(%__MODULE__{root_uri: uri})
    ~>> root
    ~>> configuration
    ~>> target
    ~>> executable
  end

  defp root(env) do
    decoded = URI.decode(URI.parse(env.root_uri).path)
    case File.cd(decoded) do
      :ok ->
        OK.success(env)
      _ ->
        OK.failure("The project root is invalid or doesn't exist.")
    end
  end

  defp executable(env) do
    cond do
      File.exists?(@asc_paths.local) ->
        OK.success(%{env | executable: Path.absname(@asc_paths.local)})
      true ->
        {_, exit} = System.cmd("which", [@asc_paths.global])
        if exit == 0 do
          OK.success(%{env | executable: @asc_paths.global})
        else
          OK.failure("No executable for AssemblyScript found.")
        end
    end
  end

  def to_string(rt = %__MODULE__{}) do
    """
    Project root: #{URI.decode(URI.parse(rt.root_uri).path)};
    AssemblyScript compiler: #{rt.executable};
    Compilation target: #{rt.target};
    """
  end

  defp configuration(env) do
    if File.exists?(@config_file_path) do
      OK.success(%{env | asconfig?: true})
    else
      OK.success(%{env | asconfig?: false})
    end
  end

  defp target(env = %__MODULE__{asconfig?: false}) do
    OK.success(%{env | target: "release"})
  end

  defp target(env = %__MODULE__{asconfig?: true}) do
    contents = File.read!(@config_file_path)
    result = Jason.decode(contents, keys: :atoms)
    
    if OK.failure?(result) do
      OK.failure("Invalid #{@config_file_path} file.")
    else
      {:ok, payload} = result
      targets = Map.get(payload, :targets, %{})
      target = Map.keys(targets) |> List.first
      if target do
        OK.success(%{env | target: Atom.to_string(target)})
      else
        OK.failure(~s(
          Your asconfig.json file should include at least one target definition.
        ))
      end
    end
  end
end
