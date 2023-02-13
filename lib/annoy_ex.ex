defmodule AnnoyEx do
  @type ok_or_err_tuple() :: :ok | {:err, String.t()}

  @moduledoc "The Spotity Annoy library as a NIF."

  @on_load {:init, 0}

  app = Mix.Project.config()[:app]

  def init do
    path = :filename.join(:code.priv_dir(unquote(app)), 'annoy')
    :ok = :erlang.load_nif(path, 0)
  end

  @doc ~S"""
    Initializes a new index that's read-write and stores vector of f dimensions.

    Available metrics:
    * `:angular` - The default.
    * `:euclidean`
    * `:manhattan`
    * `:dot`
  """
  @spec new(f :: pos_integer()) :: {:ok, reference()}
  @spec new(f :: pos_integer(), metric :: atom()) :: {:ok, reference()}
  def new(f, metric \\ :angular)

  def new(_, _) do
    exit(:nif_library_not_loaded)
  end

  @doc "Loads (mmaps) an index from disk.  Full path must be given."
  @spec load(idx :: reference(), filename :: binary()) :: ok_or_err_tuple()
  @spec load(idx :: reference(), filename :: binary(), preload :: boolean()) :: ok_or_err_tuple()
  def load(idx, filename, preload \\ false)

  def load(_, _, _) do
    exit(:nif_library_not_loaded)
  end

  @doc "Unloads."
  @spec unload(idx :: reference()) :: :ok
  def unload(idx)

  def unload(_) do
    exit(:nif_library_not_loaded)
  end

  @doc "Saves the index to disk.  Full path must be given."
  @spec save(idx :: reference(), filename :: binary()) :: ok_or_err_tuple()
  @spec save(idx :: reference(), filename :: binary(), prefault :: boolean()) :: ok_or_err_tuple()
  def save(idx, filename, prefault \\ false)

  def save(_, _, _) do
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
  @spec get_nns_by_item(
          idx :: reference(),
          i :: pos_integer(),
          n :: pos_integer(),
          search_k :: integer(),
          include_distances :: boolean()
        ) :: {list(), list()}
  def get_nns_by_item(idx, i, n, search_k \\ -1, include_distances \\ true)

  def get_nns_by_item(_, _, _, _, _) do
    exit(:nif_library_not_loaded)
  end

  @doc ~S"""
  Same as `get_nns_by_item` but query by list `v`

  Returns a 2 element tuple with two lists in it: results and distances.
  """
  @spec get_nns_by_vector(
          idx :: reference(),
          v :: list(),
          n :: pos_integer(),
          search_k :: integer(),
          include_distances :: boolean()
        ) :: {list(), list()}
  def get_nns_by_vector(_, _, _, _, _), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Returns the vector for item `i` that was previously added."
  @spec get_item_vector(idx :: reference(), i :: pos_integer()) :: list()
  def get_item_vector(idx, i)

  def get_item_vector(_, _) do
    exit(:nif_library_not_loaded)
  end

  @doc "returns the distance between items `i` and `j`."
  @spec get_distance(idx :: reference(), i :: pos_integer(), j :: pos_integer()) :: float()
  def get_distance(idx, i, j)

  def get_distance(_, _, _) do
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

  @doc "Adds item `i` (any nonnegative integer) with list `v`"
  @spec add_item(idx :: reference(), i :: pos_integer(), v :: list()) :: ok_or_err_tuple()
  def add_item(idx, i, v)

  def add_item(_, _, _) do
    exit(:nif_library_not_loaded)
  end

  @doc ~S"""
  builds a forest of `n_trees` trees. More trees gives higher precision when querying. 

  After calling build, no more items can be added. 

  `n_jobs` specifies the number of threads used to build the trees.
  `n_jobs=-1` uses all available CPU cores.
  """
  @spec build(idx :: reference(), n_trees :: pos_integer(), n_jobs :: integer()) ::
          ok_or_err_tuple()
  def build(idx, n_trees, n_jobs \\ -1)

  def build(_, _, _) do
    exit(:nif_library_not_loaded)
  end

  @doc "Unbuilds."
  @spec unbuild(idx :: reference()) :: ok_or_err_tuple()
  def unbuild(idx)

  def unbuild(_) do
    exit(:nif_library_not_loaded)
  end

  @doc ~S"""
  prepares annoy to build the index in the specified file instead of RAM 
  (execute before adding items, no need to save after build)
  """
  @spec on_disk_build(idx :: reference(), filename :: binary()) :: ok_or_err_tuple()
  def on_disk_build(idx, filename)

  def on_disk_build(_, _) do
    exit(:nif_library_not_loaded)
  end

  @doc ~S"""
  will initialize the random number generator with the given seed.

  Only used for building up the tree, i.e. only necessary to pass this before adding the items.
  Will have no effect after calling `build` or `load`
  """
  @spec set_seed(idx :: reference(), seed :: integer()) :: :ok
  def set_seed(idx, seed)

  def set_seed(_, _) do
    exit(:nif_library_not_loaded)
  end

  @doc "Set verbosity."
  @spec verbose(idx :: reference(), verbose :: boolean()) :: :ok
  def verbose(idx, verbose)

  def verbose(_, _) do
    exit(:nif_library_not_loaded)
  end
end