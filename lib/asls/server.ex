defmodule AssemblyScriptLS.Server do
  @name "AssemblyScript Language Server"
  @state %{
    initialized: false,
    root_uri: nil,
    error_codes: %AssemblyScriptLS.Server.ErrorCodes{},
    build_ref: nil,
  }

  alias AssemblyScriptLS.Server.Build
  alias AssemblyScriptLS.JsonRpc, as: RPC
  alias AssemblyScriptLS.JsonRpc.Message.{
    Request,
    Reponse,
    Notification,
    Unknown
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
  def handle_cast({:notification, %Notification{method: "textDocument/didSave"} = req}, state) do
    task = Task.async(Build, :perform, [])
    {:noreply, %{state | build_ref: task.ref}}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({ref, payload = %{}}, state) do
    for {file, diagnostics} <- payload do
      RPC.notify("textDocument/publishDiagnostics", %{
        uri: "#{state.root_uri}/#{file}",
        diagnostics: diagnostics
      })
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # --- Utilities

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
