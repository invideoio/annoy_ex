defmodule AnnoyExMultiThreadedBuildTest do
  use ExUnit.Case, async: true

  test "one thread" do
    test_building_with_threads(1)
  end

  test "two threads" do
    test_building_with_threads(2)
  end

  test "four threads" do
    test_building_with_threads(4)
  end

  test "eight threads" do
    test_building_with_threads(8)
  end

  defp test_building_with_threads(n_jobs) do
    n = 10000
    f = 10
    n_trees = 31

    i = AnnoyEx.new(f, :euclidean)

    for j <- 0..n do
      AnnoyEx.add_item(i, j, Enum.map(1..f, fn _ -> :rand.normal() end))
    end

    ret = AnnoyEx.build(i, n_trees, n_jobs)
    assert ret == :ok
    assert AnnoyEx.get_n_trees(i) == n_trees
  end
end
