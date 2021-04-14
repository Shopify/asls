use Mix.Config

config :asls, builder: AssemblyScriptLS.Server.Build.Mock
config :asls, rpc: AssemblyScriptLS.JsonRpc.Mock
config :asls, runtime: AssemblyScriptLS.Runtime.Mock
config :asls, analysis: AssemblyScriptLS.Analysis.Mock
