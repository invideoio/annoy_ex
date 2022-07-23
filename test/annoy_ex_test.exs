defmodule AnnoyExTest do
  use ExUnit.Case, async: true
  doctest AnnoyEx

  test "new/1" do
  end

  test "get_n_trees/0" do
    t = AnnoyEx.new(1)
    assert AnnoyEx.get_n_trees(t) == 0
  end

  test "readme example" do
    f = 40
    t = AnnoyEx.new(f)

    Enum.each(1..1000, fn i ->
      v = Enum.map(1..f, fn _ -> :rand.normal() end)
      AnnoyEx.add_item(t, i, v)
    end)

    AnnoyEx.build(t, 10)
    # AnnoyEx.save(t, "test.ann")
    {results, distances} = AnnoyEx.get_nns_by_item(t, 0, 1000)
    assert length(results) == 1000
    assert length(distances) == 1000
  end
end
