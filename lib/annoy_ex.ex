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
  @spec new(f :: pos_integer()) :: {:ok, reference()}
  @spec new(f :: pos_integer(), metric :: atom()) :: {:ok, reference()}
  def new(f, metric \\ :angular)

  def new(_, _) do
    exit(:nif_library_not_loaded)
  end

  @doc "Loads (mmaps) an index from disk.  Full path must be given."
  @spec load(idx :: reference(), filename :: binary()) :: atom()
  @spec load(idx :: reference(), filename :: binary(), preload :: boolean()) :: atom()
  def load(idx, filename, preload \\ false)

  def load(_,_,_) do
    exit(:nif_library_not_loaded)
  end

  @doc "Saves the index to disk.  Full path must be given."
  @spec save(idx :: reference(), filename :: binary()) :: atom()
  @spec save(idx :: reference(), filename :: binary(), preload :: boolean()) :: atom()
  def save(idx, filename, preload \\ false)

  def save(_,_,_) do
    exit(:nif_library_not_loaded)
  end

  @doc ~S"""
  Returns the `n` closest items to the item at position `i`.
  During the query it will inspect up to `search_k` nodes,
  which defaults to `n_trees * n` if not provided.
  `search_k` gives you a run-time tradeoff between better accuracy and speed.
  If you set include_distances to `true`.

  Returns a 2 element tuple with two lists in it: results and distances.
  """
  @spec get_nns_by_item(idx :: reference(), i :: pos_integer(), n :: pos_integer(), search_k :: integer(), include_distances :: boolean()) :: {list(), list()}
  def get_nns_by_item(idx, i, n, search_k \\ -1, include_distances \\ true)

  def get_nns_by_item(_,_,_,_,_) do
    exit(:nif_library_not_loaded)
  end

  @doc ~S"""
  Same as `get_nns_by_item` but query by tuple `v`

  Returns a 2 element tuple with two lists in it: results and distances.
  """
  @spec get_nns_by_vector(idx :: reference(), v :: tuple(), n :: pos_integer(), search_k :: integer(), include_distances :: boolean()) :: {list(), list()}
  def get_nns_by_vector(idx, v, n, search_k \\ -1, include_distances \\ true)

  def get_nns_by_vector(_,_,_,_,_) do
    exit(:nif_library_not_loaded)
  end

  @doc "Returns the vector for item `i` that was previously added."
  @spec get_item_vector(idx :: reference(), i :: pos_integer()) :: list()
  def get_item_vector(idx, i)

  def get_item_vector(_,_) do
    exit(:nif_library_not_loaded)
  end

  @doc "returns the distance between items `i` and `j`."
  @spec get_distance(idx :: reference(), i :: pos_integer(), j :: pos_integer()) :: float()
  def get_distance(idx, i, j)

  def get_distance(_,_,_) do
    exit(:nif_library_not_loaded)
  end

  @doc "Returns the number of items in the index."
  @spec get_n_items(idx :: reference()) :: integer()
  def get_n_items(idx)

  def get_n_items(_) do
    exit(:nif_library_not_loaded)
  end

  @doc "Returns the number of trees in the index."
  @spec get_n_trees(idx :: reference()) :: integer()
  def get_n_trees(idx)

  def get_n_trees(_) do
    exit(:nif_library_not_loaded)
  end

  @doc "Adds item `i` (any nonnegative integer) with tuple `v`"
  @spec add_item(idx :: reference(), i :: pos_integer(), v :: tuple()) :: atom()
  def add_item(idx, i, v)

  def add_item(_,_,_) do
    exit(:nif_library_not_loaded)
  end
end
