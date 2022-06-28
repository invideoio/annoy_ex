defmodule AnnoyExSeedTest do
  use ExUnit.Case, async: true

  test "test seeding" do
    f = 10
    # make a 1000 and 50 element list of 10 element lists.
    x = Enum.map(1..1000, fn _ -> Enum.map(1..10, fn _ -> :rand.uniform() end) end)
    y = Enum.map(1..50, fn _ -> Enum.map(1..10, fn _ -> :rand.uniform() end) end)

    i1 = AnnoyEx.new(f)
    i2 = AnnoyEx.new(f)

    res = AnnoyEx.set_seed(i1, 42)
    assert res == :ok
    res = AnnoyEx.set_seed(i2, 42)
    assert res == :ok

    for j <- 0..999 do
      AnnoyEx.add_item(i1, j, Enum.at(x, j))
      AnnoyEx.add_item(i2, j, Enum.at(x, j))
    end

    AnnoyEx.build(i1, 10)
    AnnoyEx.build(i2, 10)

    for k <- 0..49 do
      v = Enum.at(y, k)
      assert AnnoyEx.get_nns_by_vector(i1, v, 100) == AnnoyEx.get_nns_by_vector(i2, v, 100)
    end
  end
end
