defmodule AssemblyScriptLS.Server do
  @moduledoc """
  The AssemblyScriptLS.Server module implements the Language Server Protocol
  specification for AssemblyScript.
  """
  @name "AssemblyScript Language Server"
  @state %{
    initialized: false,
    include: "assembly/**/*.ts",
    root_uri: nil,
    error_codes: %AssemblyScriptLS.Server.ErrorCodes{},
    analyses: %{},
    runtime: %AssemblyScriptLS.Runtime{}
  }

  @rpc Application.get_env(:asls, :rpc)
  @runtime Application.get_env(:asls, :runtime)
  @analysis Application.get_env(:asls, :analysis)

  alias AssemblyScriptLS.Diagnostic
  alias AssemblyScriptLS.Assertion
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
    {payload, state} = case @runtime.ensure(params[:rootUri]) do
      {:ok, rt} ->
        {
          OK.success({:result, req.id, %{capabilities: capabilities(), serverInfo: info()}}),
          %{state | root_uri: rt.root_uri, runtime: rt}
        }
      {:error, reason} ->
        {
          OK.success({:error, req.id, %{code: state.error_codes.server_not_initialized, message: reason}}),
          state,
        }
    end

    {:reply, payload, state}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "initialized"}}, from, state) do
    GenServer.reply(from, :ok)

    @rpc.notify(
      :info,
      """
      Language server initialized with the following runtime params:

      #{@runtime.to_string(state.runtime)}
      """
    )

    unless state.runtime.asconfig? do
      @rpc.notify(
        :warning,
        """
        No asconfig.json found, consider adding one to improve the language server experience
        """
      )
    end

    {:noreply, %{state | initialized: true}}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "textDocument/didOpen"} = req}, from, state) do
    GenServer.reply(from, :ok)

    uri = req.params[:textDocument].uri
    {analysis, state} = enqueue_analysis(state, uri)
    if analysis do
      publish_diagnostics(uri, analysis.diagnostics)
      notify_assertions(analysis.assertions)
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "textDocument/didSave"} = req}, from, state) do
    GenServer.reply(from, :ok)
    {_, state} = enqueue_analysis(state, req.params[:textDocument].uri)
    {:noreply, state}
  end

  @impl true
  def handle_call({:notification, %Notification{method: "workspace/didChangeConfiguration"} = req}, from, state) do
    GenServer.reply(from, :ok)
    include = req.params[:settings][:asls][:include]

    if include do
      {:noreply, %{state | include: include}}
    else
      {:noreply, state}
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

  # When receiving an info message from a task, we are certain that it refers
  # to a valid analysis and to an analyzable document. That's the reason why we
  # don't perform any check to see if the analysis exists.
  @impl true
  def handle_info({_ref, {uri, payload}}, state) do
    {diagnostics, assertions} = split_analysis_payload(payload)
    publish_diagnostics(uri, diagnostics)
    notify_assertions(assertions)

    analysis = state.analyses[uri]
               |> @analysis.diagnostics(diagnostics)
               |> @analysis.assertions(assertions)

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

  defp enqueue_analysis(state, uri) do
    case analyzable?(state.root_uri, uri, state.include) do
      true ->
        analysis = state.analyses[uri]
        if analysis do
          analysis = @analysis.reenqueue(analysis)
          {analysis, %{state | analyses: Map.put(state.analyses, uri, analysis)}}
        else
          analysis = @analysis.new(state.runtime, uri)
          {analysis, %{state | analyses: Map.put_new(state.analyses, uri, analysis)}}
        end
      false ->
        {nil, state}
    end
  end

  defp split_analysis_payload(payload) do
    Enum.split_with(payload, fn e ->
      case e do
        %Diagnostic{} -> true
        %Assertion{} -> false
      end
    end)
  end

  defp analyzable?(root_uri, target_uri, glob) do
    target_path = URI.decode(URI.parse(target_uri).path)
    root_path = URI.decode(URI.parse(root_uri).path)
    relative = Path.relative_to(target_path, root_path)
    :glob.matches(relative, glob)
  end

  defp publish_diagnostics(uri, diagnostics) do
    @rpc.notify("textDocument/publishDiagnostics", %{
      uri: uri,
      diagnostics: diagnostics,
    })
  end

  def notify_assertions(assertions) do
    case assertions do
      [] -> :ok
      as ->
        @rpc.notify(
          :error,
          """
          The assemblyscript compiler (asc) crashed.
          Check the content of the crash, and submit an
          issue or pull-request upstream.
          """
        )
        Enum.each(as, fn a ->
          @rpc.notify(:error, a.contents)
        end)
    end
  end
end
