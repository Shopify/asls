defmodule AssemblyScriptLS.Editors.VSCode do
  require OK
  use OK.Pipe

  @typescript_validate_key "typescript.validate.enable"

  defmodule Config do
    defstruct [:package_json, :settings]

    def new do
      case File.cwd() do
        {:ok, dir} ->
          %__MODULE__{
            package_json: Path.join(dir, "package.json"),
            settings: Path.join(dir, ".vscode/settings.json")
          }
        e -> e
      end
    end
  end

  def setup do
    OK.wrap(Config.new())
    ~>> ensure_package_definition
    ~>> write_vscode_settings
  end

  defp ensure_package_definition(config) do
    if File.exists?(config.package_json) do
      OK.success(config)
    else
      OK.failure("""
      No package.json found. Make sure you define one and
      that you run `asls setup EDITOR` from the root of your
      project.
      """)
    end
  end

  defp write_vscode_settings(config) do
    path = config.settings
    if File.exists?(path) do
      update_settings(path)
    else
      File.mkdir_p!(Path.dirname(path))
      File.touch!(path)
      create_settings(path)
    end
  end

  defp create_settings(at) do
    json = Jason.encode!(%{@typescript_validate_key => false}, pretty: true)
    case File.write(at, json) do
      :ok ->
        OK.wrap(:ok)
      {:error, e} ->
        OK.failure("Couldn't create vscode settings at: #{at}, error: #{e}")
    end
  end

  defp update_settings(path) do
    json = File.read!(path)
    case Jason.decode(json) do
      {:ok, settings} ->
        update_settings_map(path, settings)
      {:error, e} ->
        OK.failure("Invalid json found at #{path}, error: #{e}")
    end
  end

  defp update_settings_map(_, %{@typescript_validate_key => false}), do: OK.wrap(:ok)
  defp update_settings_map(path, map = %{@typescript_validate_key => true}) do
    json = Jason.encode!(%{map | @typescript_validate_key => false}, pretty: true)
    case File.write(path, json) do
      :ok ->
        OK.wrap(:ok)
      {:error, e} ->
        OK.failure("Couldn't write vscode settings to #{path}, error: #{e}")
    end
  end

  defp update_settings_map(path, map) do
    json = Jason.encode!(Map.put_new(map, @typescript_validate_key, false), pretty: true)
    case File.write(path, json) do
      :ok ->
        OK.wrap(:ok)
      {:error, e} ->
        OK.failure("Couldn't write vscode settings to #{path}, error: #{e}")
    end
  end
end
