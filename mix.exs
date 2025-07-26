defmodule Mapx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source "https://github.com/x1aaff/mapx"

  def project do
    [
      app: :mapx,
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      name: "MapX",
      source_url: @source,
      description: "Extended map operations for Elixir."
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end
end
