defmodule AnnoyEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :annoy_ex,
      version: "1.0.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      compilers: [:elixir_make] ++ Mix.compilers(),

      # Docs
      name: "AnnoyEx",
      source_url: "https://github.com/dallaselynn/annoy_ex",
      homepage_url: "https://hexdocs.pm/annoy_ex",
      docs: [
        main: "readme",
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:random, "~> 0.2.4", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:elixir_make, "~> 0.4", runtime: false},
    ]
  end

  defp description() do
    "A NIF binding to Spotify's Annoy C++ library for approximate nearest neighbors."
  end

  defp package() do
    [
      maintainers: ["Dallas Lynn"],
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* src Makefile test),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/dallaselynn/annoy_ex"}
    ]
  end
end
