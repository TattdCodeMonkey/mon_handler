defmodule MonHandler.Mixfile do
  use Mix.Project

  def project do
    [app: :mon_handler,
     version: "1.0.0",
     elixir: "~> 1.0",
     deps: deps,
     package: package]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Rodney Norris"],
      licenses: ["MIT"],
      links: [{"Github", "https://github.com/tattdcodemonkey/mon_handler"}]
    ]
  end
end
