defmodule AssemblyScriptLS.Environment do
  alias AssemblyScriptLS.Editors
  require OK

  @editors ["vscode"]

  @spec format_supported_editors :: String.t
  def format_supported_editors, do: Enum.join(@editors, ", ")

  def setup_editor(editor) do
    case normalize(editor) do
      "vscode" ->
        case Editors.VSCode.setup() do
          {:ok, _} ->
            IO.puts("VSCode setup successful")
          {:error, e} ->
            IO.puts(:stderr, """
            Couldn't setup VSCode:

            #{e}
            """)
        end
      e ->
        OK.failure("No editor found for: #{e}")
    end
  end

  @spec supported_editors :: [String.t]
  def supported_editors, do: @editors

  @spec supported_editor?(String.t) :: boolean()
  def supported_editor?(editor) do
    normalize(editor) in @editors
  end

  defp normalize(editor) do
    String.downcase(editor)
  end
end
