defmodule AssemblyScriptLS.Server do
  @moduledoc """
  The AssemblyScriptLS.Server module implements the Language Server Protocol
  specification for AssemblyScript.
  """
  @name "AssemblyScript Language Server"
  @state %{
    initialized: false,
    root_uri: nil,
    error_codes: %AssemblyScriptLS.Server.ErrorCodes{},
    build_ref: nil,
    diagnostics: %{},
    building?: false,
    rebuild?: false,
    documents: [],
  }

  @builder Application.get_env(:asls, :builder)
  @rpc Application.get_env(:asls, :rpc)

  alias AssemblyScriptLS.JsonRpc.Message.{
    Request,
    Notification,
  }

  use GenServer
  
  require OK

  # --- Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, @state, name: name)
  end

  def handle_request(request, name \\ __MODULE__) do
    GenServer.call(name, {:request, request})
  end

  def handle_notification(notification, name \\ __MODULE__) do
    GenServer.call(name, {:notification, notification})
  end

  def name, do: @name

  # --- Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:request, %Request{method: "initialize", params: params} = req}, _from, state) do
    root_uri =
      URI.decode(URI.parse(params[:rootUri]).path)

    {payload, state} = case File.cd(root_uri) do
      :ok ->
        {
          OK.success({:result, req.id, %{capabilities: capabilities(), serverInfo: info()}}),
          %{state | root_uri: params[:rootUri]}
        }
      _ ->
        message = """
        Couldn't initialize the server.
        The project root is invalid or doesn't exist.
        """
        {
          OK.success({:error, req.id, %{code: state.error_codes.server_not_initialized, message: message}}),
          state
        }
    end

    {:reply, payload, state}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "initialized"}}, _from, state) do
    {:reply, :ok, %{state | initialized: true}}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "workspace/didChangeConfiguration"}}, _from, state) do
    cond do
      state.building? ->
        {:reply, :ok, %{state | rebuild?: true}}
      true ->
        task = @builder.perform(%{root_uri: state.root_uri})
        {:reply, :ok, %{state | build_ref: task.ref, building?: true, rebuild?: false}}
    end
  end

  @impl true
  def handle_call({:notification, %Notification{method: "textDocument/didOpen"} = req}, from, state) do
    GenServer.reply(from, :ok)
    uri = req.params[:textDocument].uri

    @rpc.notify("textDocument/publishDiagnostics", %{
      uri: uri,
      diagnostics: state.diagnostics[uri] || []
    })

    state =
      cond do
        Enum.find(state.documents, &(&1 == uri)) ->
          state
        true ->
          %{state | documents: [uri | state.documents]}
      end

    {:noreply, state}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "textDocument/didSave"} = _req}, _from, state) do
    cond do
      state.building? ->
        {:reply, :ok, %{state | rebuild?: true}}
      true ->
        task = @builder.perform(%{root_uri: state.root_uri})
        {:reply, :ok, %{state | build_ref: task.ref, building?: true, rebuild?: false}}
    end
  end

  @impl true
  def handle_call(_, _, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({_ref, payload = %{}}, state) do
    for doc <- state.documents do
      @rpc.notify("textDocument/publishDiagnostics", %{
        uri: doc,
        diagnostics: payload[doc] || [],
      })
    end

    {:noreply, %{state | diagnostics: payload}}
  end

  @impl true
  def handle_info({:DOWN, _, _, _, _}, state) do
    cond do
      state.rebuild? ->
        task = @builder.perform(%{root_uri: state.root_uri})
        {:noreply, %{state | rebuild?: false, building?: true, build_ref: task.ref}}
      true ->
        {:noreply, %{state | building?: false, build_ref: nil}}
    end
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # --- Helpers

  defp capabilities do
    %{
      textDocumentSync: 2,
    }
  end

  defp info do
    %{
      name: @name,
    }
  end
end
