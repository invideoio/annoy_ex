# AnnoyEx

**TODO: Add description**
Elixir NIF port of https://github.com/spotify/annoy

Resources:
https://www.erlang.org/doc/man/erl_nif.html
https://github.com/ulfl/setconcile
https://github.com/devinus/markdown
https://github.com/bdt-group/clickhouse_parser

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `annoy_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:annoy_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/annoy_ex](https://hexdocs.pm/annoy_ex).

TODO:

Wrap NIF resource in a module:

defmodule DBConn do
  defstruct [:resource]

  defimpl Inspect do
    # ...
  end
end