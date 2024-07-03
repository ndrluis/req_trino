defmodule ReqTrino.MixProject do
  use Mix.Project

  @version "0.1.1"
  @description "Req plugin for Trino"

  def project do
    [
      app: :req_trino,
      version: @version,
      description: @description,
      name: "ReqTrino",
      elixir: "~> 1.14",
      preferred_cli_env: [
        "test.all": :test,
        docs: :docs,
        "hex.publish": :docs
      ],
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      aliases: aliases(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/ndrluis/req_trino",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.3.5"},
      {:table, "~> 0.1.1", optional: true},
      {:tzdata, "~> 1.1.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  def aliases do
    ["test.all": ["test --include integration"]]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/ndrluis/req_trino"
      }
    ]
  end
end
