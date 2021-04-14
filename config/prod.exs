use Mix.Config

config :asls, builder: AssemblyScriptLS.Server.Build
config :asls, rpc: AssemblyScriptLS.JsonRpc
config :asls, runtime: AssemblyScriptLS.Runtime
config :asls, analysis: AssemblyScriptLS.Analysis
