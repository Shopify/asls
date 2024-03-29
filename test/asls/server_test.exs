defmodule AssemblyScriptLS.ServerTest do
  @process TestServer
  @fs_root_path "./path"
  @root_uri "file:///Developer/astest"
  @document_uri "file:///Developer/astest/assembly/foo/foo.ts"
  alias AssemblyScriptLS.Server
  alias AssemblyScriptLS.JsonRpc.Message

  import Mox

  use ExUnit.Case, async: true

  setup do
    start_supervised!({Server, name: @process})
    :ok = File.mkdir_p(@fs_root_path)

    set_allowances()

    on_exit(fn -> File.rm_rf!(@fs_root_path) end)
  end

  def set_allowances do
    [
      AssemblyScriptLS.JsonRpc.Mock,
      AssemblyScriptLS.Runtime.Mock,
      AssemblyScriptLS.Analysis.Mock,
    ]
    |> Enum.each(fn mock -> allow(mock, self(), @process) end)
  end

  setup :verify_on_exit!

  describe "handle_request/2" do
    test "on initialize request: initializes the server when the project uri exists" do
      params = %{rootUri: @fs_root_path}
      req = Message.new(%{jsonrpc: Message.rpc_version, id: 1, method: "initialize", params: params})

      AssemblyScriptLS.Runtime.Mock
      |> expect(:ensure, fn _ -> {:ok, %{root_uri: @fs_root_path, asconfig?: true}} end)

      {:ok, {type, id, server_info}} = Server.handle_request(req, @process)

      assert type == :result
      assert id == 1
      assert server_info == %{
        capabilities: %{textDocumentSync: 2},
        serverInfo: %{name: "AssemblyScript Language Server"},
      }

      state = :sys.get_state(@process)
      assert state[:root_uri] == @fs_root_path
    end

    test "on initialize request: responds with -32002 when the project uri does not exist" do
      params = %{rootUri: @root_uri}
      req = Message.new(%{jsonrpc: Message.rpc_version, id: 1, method: "initialize", params: params})

      AssemblyScriptLS.Runtime.Mock
      |> expect(:ensure, fn _ -> {:error, "The project root is invalid or doesn't exist."} end)

      {:ok, {type, id, payload}} = Server.handle_request(req, @process)

      assert type == :error
      assert id == 1
      assert payload == %{
        code: -32002,
        message: "The project root is invalid or doesn't exist."
      }
      state = :sys.get_state(@process)
      refute state[:root_uri]
    end
  end

  describe "handle_notification/2" do
    test "on initialized notification: sets the server state to initialized" do
      notification = Message.new(%{jsonrpc: Message.rpc_version, method: "initialized", params: %{}})

      AssemblyScriptLS.JsonRpc.Mock
      |> expect(:notify, fn :info, _ -> :ok end)
      |> expect(:notify, fn :warning, _ -> :ok end)


      AssemblyScriptLS.Runtime.Mock
      |> expect(:to_string, fn _ -> "" end)

      :ok = Server.handle_notification(notification, @process)
      state = :sys.get_state(@process)
      assert state[:initialized]
    end

    test "on textDocument/didOpen adds an analysis entry" do
      replace_state_with(%{root_uri: @root_uri})
      params = %{textDocument: %{uri: @document_uri}}
      diagnostics = %{uri: @document_uri, diagnostics: []}

      AssemblyScriptLS.JsonRpc.Mock
      |> expect(:notify, fn "textDocument/publishDiagnostics", ^diagnostics -> :ok end)

      AssemblyScriptLS.Analysis.Mock
      |> expect(:new, fn _, _ -> %{diagnostics: [], assertions: []} end)

      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "textDocument/didOpen", params: params})
        |> Server.handle_notification(@process)

      assert current_state().analyses[@document_uri]
    end

    test "on textDocument/didSave an analysys is reenqueued if an analysis exists" do
      params = %{textDocument: %{uri: @document_uri}}

      replace_state_with(
        %{analyses: %{@document_uri => %{diagnostics: []}}, root_uri: @root_uri}
      )

      AssemblyScriptLS.Analysis.Mock
      |> expect(:reenqueue, fn _ -> %{diagnostics: []} end)

      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "textDocument/didSave", params: params})
        |> Server.handle_notification(@process)

      assert current_state().analyses[@document_uri]
    end

    test "on textDocument/didSave an analysis is created if no analysis exists" do
      params = %{textDocument: %{uri: @document_uri}}

      replace_state_with(%{root_uri: @root_uri})

      AssemblyScriptLS.Analysis.Mock
      |> expect(:new, fn _, _ -> %{diagnostics: []} end)

      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "textDocument/didSave", params: params})
        |> Server.handle_notification(@process)

      assert current_state().analyses[@document_uri]
    end

    test "on workspace/DidChangeConfiguration the include setting is saved" do
      params = %{settings: %{asls: %{include: ["assembly/**/*.as"]}}}
      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "workspace/didChangeConfiguration", params: params})
        |> Server.handle_notification(@process)

      assert current_state().include  == ["assembly/**/*.as"]
    end
  end

  defp replace_state_with(params = %{}) do
    :sys.replace_state(@process, fn state ->
      Map.merge(state, params)
    end)
  end

  defp current_state do
    :sys.get_state(@process)
  end
end
