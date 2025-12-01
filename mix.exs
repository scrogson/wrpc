defmodule Wrpc.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/scrogson/wrpc"

  def project do
    [
      app: :wrpc,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Wrpc",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.34.0", runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Elixir NIF bindings for wRPC - WebAssembly component-native RPC framework.
    """
  end

  defp package do
    [
      name: "wrpc",
      files: ~w(lib native .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "wRPC" => "https://github.com/bytecodealliance/wrpc"
      }
    ]
  end

  defp docs do
    [
      main: "Wrpc",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
