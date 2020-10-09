use Mix.Config

config :asls, builder: AssemblyScriptLS.Server.Build.Mock
config :asls, rpc: AssemblyScriptLS.JsonRpc.Mock
