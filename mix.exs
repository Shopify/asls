defmodule AssemblyScriptLS.MixProject do
  use Mix.Project

  def project do
    [
      app: :asls,
      version: version(),
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},
      {:ok, "~> 2.3"},
      {:jason, "~> 1.2"},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp escript do
    [
      main_module: AssemblyScriptLS.CLI,
      path: "bin/asls"
    ]
  end

  defp aliases do
    [
      compile: ["compile --warnings-as-errors"]
    ]
  end

  defp version, do: "0.5.1"

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_),     do: ["lib"]
end
