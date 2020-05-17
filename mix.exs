defmodule AssemblyScriptLS.MixProject do
  use Mix.Project

  def project do
    [
      app: :asls,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5"}
    ]
  end

  defp escript do
    [main_module: AssemblyScriptLS.CLI]
  end
end
