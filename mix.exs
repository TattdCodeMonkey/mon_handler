defmodule MonHandler.Mixfile do
  use Mix.Project

  def project do
    [app: :mon_handler,
     version: "1.0.2",
     elixir: "~> 1.0",
     deps: deps,
     description: description,
     package: package]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mock, "~> 0.1.1", only: :test},
      {:dialyze, "~> 0.2.0", optional: true}
    ]
  end

  defp description do
    """
    A minimal GenServer that monitors a given GenEvent handler.

    This server will handle exits of the Handler and attempt to re-add it
    to the manager when unexpected exits occur.

    Exits for :normal, :shutdown or :swapped reasons will not attempt a re-add to
    the manager.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Rodney Norris"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tattdcodemonkey/mon_handler"}
    ]
  end
end
