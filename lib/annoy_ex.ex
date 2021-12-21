defmodule AnnoyEx do
  @moduledoc """
  The Spotity Annoy library as a NIF.
  """

  @on_load { :init, 0 }

  app = Mix.Project.config[:app]

  def init do
    path = :filename.join(:code.priv_dir(unquote(app)), 'annoy')
    :ok = :erlang.load_nif(path, 0)
  end

  @doc ~S"""
    Initializes a new index that's read-write and stores vector of f dimensions.
    Converts a Markdown document to HTML:
        iex> Markdown.to_html "# Hello World"
        "<h1>Hello World</h1>\n"
        iex> Markdown.to_html "http://elixir-lang.org/", autolink: true
        "<p><a href=\"http://elixir-lang.org/\">http://elixir-lang.org/</a></p>\n"

    Available metrics:
    * `:angular` - The default.
    * `:euclidean`
    * `:manhattan`
    * `:hamming`
    * `:dot`
  """
  @spec new(f :: pos_integer(), metric :: atom()) :: {:ok, reference()}
  def new(f, metric \\ :angular)

  def new(_, _) do
    exit(:nif_library_not_loaded)
  end
end
