defmodule AssemblyScriptLS.ServerTest do
  @process TestServer
  @root_path "./path"
  alias AssemblyScriptLS.Server
  alias AssemblyScriptLS.JsonRpc.Message

  import Mox

  use ExUnit.Case, async: true

  setup do
    start_supervised!({Server, name: @process})
    :ok = File.mkdir_p(@root_path)

    set_allowances()

    on_exit(fn -> File.rm_rf!(@root_path) end)
  end

  def set_allowances do
    [AssemblyScriptLS.Server.Build.Mock, AssemblyScriptLS.JsonRpc.Mock]
    |> Enum.each(fn mock -> allow(mock, self(), @process) end)
  end

  setup :verify_on_exit!

  describe "handle_request/2" do
    test "on initialize request: initializes the server when the project uri exists" do
      params = %{rootUri: @root_path}
      req = Message.new(%{jsonrpc: Message.rpc_version, id: 1, method: "initialize", params: params})
      {:ok, {type, id, server_info}} = Server.handle_request(req, @process)
      assert type == :result
      assert id == 1
      assert server_info == %{
        capabilities: %{textDocumentSync: 2},
        serverInfo: %{name: "AssemblyScript Language Server"},
      }
      state = :sys.get_state(@process)
      assert state[:root_uri] == @root_path
    end

    test "on initialize request: responds with -32002 when the project uri does not exist" do
      params = %{rootUri: "./foo"}
      req = Message.new(%{jsonrpc: Message.rpc_version, id: 1, method: "initialize", params: params})
      {:ok, {type, id, payload}} = Server.handle_request(req, @process)
      assert type == :error
      assert id == 1
      assert payload == %{
        code: -32002,
        message: """
        Couldn't initialize the server.
        The project root is invalid or doesn't exist.
        """
      }
      state = :sys.get_state(@process)
      refute state[:root_uri]
    end
  end

  describe "handle_notification/2" do
    test "on initialized notification: sets the server state to initialized" do
      notification = Message.new(%{jsonrpc: Message.rpc_version, method: "initialized", params: %{}})
      :ok = Server.handle_notification(notification, @process)
      state = :sys.get_state(@process)
      assert state[:initialized]
    end

    test "on workspace/didChangeConfiguration notification: performs a build" do
      AssemblyScriptLS.Server.Build.Mock
      |> expect(:perform, fn _params -> %{ref: 1} end)

      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "workspace/didChangeConfiguration", params: %{}})
        |> Server.handle_notification(@process)

      state = :sys.get_state(@process)
      assert state.building?
      refute state.rebuild?
      assert state.build_ref == 1
    end

    test "on workspace/didChangeConfiguration notification: enqueues a rebuild if a build is in progress" do
      :sys.replace_state(@process, fn state -> %{state | building?: true} end)
      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "workspace/didChangeConfiguration", params: %{}})
        |> Server.handle_notification(@process)

      state = :sys.get_state(@process)
      assert state.building?
      assert state.rebuild?
    end

    test "on textDocument/didOpen adds the document to the state" do
      document = "file://path/to/doc.ts"
      params = %{textDocument: %{uri: document}}
      diagnostics = %{uri: document, diagnostics: []}

      AssemblyScriptLS.JsonRpc.Mock
      |> expect(:notify, fn "textDocument/publishDiagnostics", ^diagnostics -> :ok end)

      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "textDocument/didOpen", params: params})
        |> Server.handle_notification(@process)

      state = :sys.get_state(@process)
      assert document in state.documents
    end

    test "on textDocument/didSave a rebuild is enqueued if a build is in progress " do
      :sys.replace_state(@process, fn state -> %{state | building?: true} end)
      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "textDocument/didSave", params: %{}})
        |> Server.handle_notification(@process)

      state = :sys.get_state(@process)
      assert state.rebuild?
    end

    test "on textDocument/didSave a build is triggered if no build is in progress" do
      AssemblyScriptLS.Server.Build.Mock
      |> expect(:perform, fn _params -> %{ref: 1} end)

      :ok =
        Message.new(%{jsonrpc: Message.rpc_version, method: "textDocument/didSave", params: %{}})
        |> Server.handle_notification(@process)

      state = :sys.get_state(@process)
      assert state.build_ref == 1
      assert state.building?
      refute state.rebuild?
    end
  end
end
