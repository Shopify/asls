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
    analyses: %{},
    runtime: nil
  }

  @rpc Application.get_env(:asls, :rpc)
  @runtime Application.get_env(:asls, :runtime)
  @analysis Application.get_env(:asls, :analysis)

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

    # FIXME: Ensure that runtime dependencies are met
    # before blindly initializing the server
    {:ok, rt} = @runtime.ensure(params[:rootUri])
    {:reply, payload, %{state | runtime: rt}}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "initialized"}}, _from, state) do
    {:reply, :ok, %{state | initialized: true}}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "textDocument/didOpen"} = req}, from, state) do
    GenServer.reply(from, :ok)

    uri = req.params[:textDocument].uri
    state = enqueue_analysis(state, uri)

    @rpc.notify("textDocument/publishDiagnostics", %{
      uri: uri,
      diagnostics: state.analyses[uri].diagnostics
    })

    {:noreply, state}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "textDocument/didSave"} = req}, from, state) do
    GenServer.reply(from, :ok)
    state = enqueue_analysis(state, req.params[:textDocument].uri)
    {:noreply, state}
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
  def handle_info({_ref, {uri, payload}}, state) do
    @rpc.notify("textDocument/publishDiagnostics", %{
      uri: uri,
      diagnostics: payload
    })

    analysis = state.analyses[uri]
               |> @analysis.diagnostics(payload)

    state = %{state | analyses: Map.put(state.analyses, uri, analysis)}

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _, _, _, _}, state) do
    {:noreply, state}
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

  def enqueue_analysis(state, uri) do
    analysis = state.analyses[uri]
    if analysis do
      analysis = @analysis.reenqueue(analysis)
      %{state | analyses: Map.put(state.analyses, uri, analysis)}
    else
      analysis = @analysis.new(state.runtime, uri)
      %{state | analyses: Map.put_new(state.analyses, uri, analysis)}
    end
  end
end
