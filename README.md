# AnnoyEx

A NIF binding to [Annoy](https://github.com/spotify/annoy), Spotify's C++ library for
approximate nearest neighbors.

It implements all of the methods in the Spotify library and all index types except Hamming.


# Code Examples

## If you have your own vectors.

  ```elixir
  iex(1)> f = 40
  40

  iex(2)> t = AnnoyEx.new(f)
  #Reference<0.3703577626.1733689351.247165>

  iex(3)> Enum.each(0..999,
  ...(3)>   fn i -> AnnoyEx.add_item(t, i, Enum.map(0..f-1, fn _ -> :rand.normal() end))
  ...(3)> end)
  :ok

  iex(4)> AnnoyEx.build(t, 10)
  :ok

  iex(5)> AnnoyEx.save(t, "test.ann")
  :ok

  iex(6)> u = AnnoyEx.new(f, :angular)
  #Reference<0.3703577626.1733689345.248447>

  iex(7)> AnnoyEx.load(u, "test.ann") # super fast, will just mmap the file
  :ok

  iex(8)> AnnoyEx.get_nns_by_item(u, 0, 10) # will find the 10 nearest neighbors
  {[0, 677, 837, 478, 793, 183, 265, 623, 751, 268],
  [0.0, 1.1232969760894775, 1.1271791458129883, 1.1428979635238647,
  1.1504143476486206, 1.1632753610610962, 1.1647002696990967,
  1.1801577806472778, 1.2018792629241943, 1.2058889865875244]}
  ```

## Word Embeddings with Pretrained GloVe vectors

  Go to https://nlp.stanford.edu/projects/glove/ and download a word-embedding file, eg.
  https://nlp.stanford.edu/data/glove.42B.300d.zip

  By its nature creating and building the index can be quite slow but querying afterward
  is fast.  Saving built indexes can help with this.

  ```elixir
     # Build and save the index.
     idx = AnnoyEx.new(300)

     index_to_word =
       File.stream!("glove.42B.300d.txt") |>
       Stream.with_index() |>
       Stream.map(fn {line,item} ->
         fields = String.trim_trailing(line) |> String.split(" ")
         word = hd(fields)
         vec = Enum.map(tl(fields), fn x -> Float.parse(x) |> elem(0) end)
         AnnoyEx.add_item(idx, item, vec)
         {item, word}
       end) |>
       Enum.into(%{})

     AnnoyEx.build(idx,10)

     AnnoyEx.save(idx, "glove.42B.300d.idx")
     File.write!("glove.42B.300d.i2w", :erlang.term_to_binary(index_to_word))
  ```

  The saved data can now be queried for similar words, eg. the 10 closest words to "dog":

  ```
  iex(1)> index_to_word = File.read!("glove.42B.300d.i2w") |> :erlang.binary_to_term
  %{
    1774702 => "bedanya",
    ...
  }

  iex(2)> word_to_index = Map.new(index_to_word, fn {k, v} -> {v, k} end)
  %{
    "timout" => 816588,
    ...
  }

  iex(3)> idx = AnnoyEx.new(300)
  #Reference<0.2696563938.657326081.165701>

  iex(4)> AnnoyEx.load(idx, "glove.42B.300d.idx")
  :ok

  iex(5)> dog_id = word_to_index["dog"]
  828

  iex(6)> {word_ids, distances} = AnnoyEx.get_nns_by_item(idx, dog_id, 10)
  {[828, 1818, 5203, 3394, 1642, 1937, 6798, 16091, 7080, 16440],
   [0.0, 0.5301183462142944, 0.617365300655365, 0.7635669112205505,
    0.8098030686378479, 0.8700820803642273, 0.8896471261978149,
    0.8973260521888733, 0.9196945428848267, 0.9411463737487793]}

  iex(7)> Enum.map(word_ids, fn word_id -> index_to_word[word_id] end)
  ["dog", "dogs", "puppy", "cats", "animal", "horse", "rabbit", "paws", "pig",
   "paw"]
  ```


# Installation

*n.b. This library currently only runs on Linux.*

You will need a C++14 compiler and the Erlang header files required for compiling NIFs.

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `annoy_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:annoy_ex, "~> 1.0.0"}
  ]
end
```

# Working with source

Before running tests make sure to build the shared library with `make annoy`
