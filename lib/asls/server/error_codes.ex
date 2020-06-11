defmodule AssemblyScriptLS.Server.ErrorCodes do
  defstruct [
    parse_error: -32700,
    invalid_request: -32600,
    method_not_found: -32601,
    invalid_params: -32602,
    internal_error: -32603,
    server_error_start: -32099,
    server_error_end: -32000,
    server_not_initialized: -32002,
    unknown_error_code: -32001,
    request_cancelled: -32800,
    content_modified: -32801,
  ]
end
