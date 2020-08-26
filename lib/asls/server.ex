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

  alias AssemblyScriptLS.Server.Build
  alias AssemblyScriptLS.JsonRpc, as: RPC
  alias AssemblyScriptLS.JsonRpc.Message.{
    Request,
    Notification,
  }

  use GenServer
  
  # --- Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, @state, name: name)
  end

  def handle_request(request, name \\ __MODULE__) do
    GenServer.cast(name, {:request, request})
  end

  def handle_notification(notification, name \\ __MODULE__) do
    GenServer.cast(name, {:notification, notification})
  end

  def name, do: @name

  # --- Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:request, %Request{method: "initialize", params: params} = req}, state) do
    root_uri = 
      URI.decode(URI.parse(params[:rootUri]).path)


    case File.cd(root_uri) do
      :ok ->
        RPC.respond(:result, req.id, %{
          capabilities: capabilities(),
          serverInfo: info(),
        })
      _ ->
        message = """
        Couldn't initialize the server.
        The project root is invalid or doesn't exist.
        """
        RPC.respond(:error, req.id, %{
          code: state.error_codes.server_not_initialized,
          message: message
        })
    end


    {:noreply, %{state | root_uri: params[:rootUri]}}
  end

  @impl true
  def handle_cast({:notification, %Notification{method: "initialized"}}, state) do
    {:noreply, %{state | initialized: true}}
  end

  @impl true
  def handle_cast({:notification, %Notification{method: "workspace/didChangeConfiguration"}}, state) do
    cond do
      state.building? ->
        {:noreply, %{state | rebuild?: true}}
      true ->
        task = Build.perform(state.root_uri)
        {:noreply, %{state | build_ref: task.ref, building?: true, rebuild?: false}}
    end
  end

  @impl true
  def handle_cast({:notification, %Notification{method: "textDocument/didOpen"} = req}, state) do
    uri = req.params[:textDocument].uri

    RPC.notify("textDocument/publishDiagnostics", %{
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
  def handle_cast({:notification, %Notification{method: "textDocument/didSave"} = _req}, state) do
    cond do
      state.building? ->
        {:noreply, %{state | rebuild?: true}}
      true ->
        task = Build.perform(state.root_uri)
        {:noreply, %{state | build_ref: task.ref, building?: true, rebuild?: false}}
    end
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({_ref, payload = %{}}, state) do
    for doc <- state.documents do
      RPC.notify("textDocument/publishDiagnostics", %{
        uri: doc,
        diagnostics: payload[doc] || [],
      })
    end

    {:noreply, %{state | diagnostics: payload}}
  end

  # check if this gets called
  @impl true
  def handle_info({:DOWN, _, _, _, _}, state) do
    cond do
      state.rebuild? ->
        task = Build.perform(state.root_uri)
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
      "textDocumentSync" => 2,
    }
  end

  defp info do
    %{
      name: @name,
    }
  end
end
