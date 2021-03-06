defmodule MeshxConsul.MixProject do
  use Mix.Project

  @source_url "https://github.com/andrzej-mag/meshx_consul"
  @version "0.1.0"

  def project do
    [
      app: :meshx_consul,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "MeshxConsul",
      description: "Consul service mesh adapter"
    ]
  end

  def application, do: [extra_applications: [:logger, :inets], mod: {MeshxConsul.Application, []}]

  defp deps do
    [
      {:bbmustache, "~> 1.11"},
      {:jason, "~> 1.2"},
      {:erlexec, "~> 1.17"},
      {:ex_doc, "~> 0.24.2", only: :dev, runtime: false},
      {:meshx, "~> 0.1.0"},
      {:nimble_options, "~> 0.3.5"}
    ]
  end

  defp package do
    [
      files: ~w(lib docs .formatter.exs mix.exs),
      maintainers: ["Andrzej Magdziarz"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "MeshxConsul",
      assets: "docs/assets",
      source_url: @source_url,
      source_ref: "v#{@version}",
      deps: [
        meshx_node: "https://hexdocs.pm/meshx_node",
        meshx_rpc: "https://hexdocs.pm/meshx_rpc"
      ]
    ]
  end
end
