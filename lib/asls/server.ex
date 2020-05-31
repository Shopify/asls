defmodule AssemblyScriptLS.Server do
  @state %{}
  @name "asls"

  alias AssemblyScriptLS.JsonRpc
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

  # --- Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:request, %Request{method: "initialize"} = req}, state) do
    result = %{
      "capabilities" => capabilities(),
      "serverInfo" => info(),
    }

    JsonRpc.respond(req.id, result, :result)

    {:noreply, state}
  end

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
