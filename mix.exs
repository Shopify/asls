defmodule AssemblyScriptLS.MixProject do
  use Mix.Project

  @v "0.1.1"

  def project do
    [
      app: :asls,
      version: @v,
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
    [
      main_module: AssemblyScriptLS.CLI,
      path: "bin/asls"
    ]
  end
end
