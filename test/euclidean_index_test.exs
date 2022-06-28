defmodule AnnoyExEuclideanIndexTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  test "get_nns_by_vector" do
    f = 2
    i = AnnoyEx.new(f, :euclidean)
    AnnoyEx.add_item(i, 0, [2, 2])
    AnnoyEx.add_item(i, 1, [3, 2])
    AnnoyEx.add_item(i, 2, [3, 3])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 4], 3)
    assert res == [2, 1, 0]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [1, 1], 3)
    assert res == [0, 1, 2]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 2], 3)
    assert res == [1, 2, 0]
  end

  test "get_nns_by_item" do
    i = AnnoyEx.new(2, :euclidean)
    AnnoyEx.add_item(i, 0, [2, 2])
    AnnoyEx.add_item(i, 1, [3, 2])
    AnnoyEx.add_item(i, 2, [3, 3])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_item(i, 0, 3)
    assert res == [0, 1, 2]
    {res, _} = AnnoyEx.get_nns_by_item(i, 2, 3)
    assert res == [2, 1, 0]
  end

  test "dist" do
    i = AnnoyEx.new(2, :euclidean)
    AnnoyEx.add_item(i, 0, [0, 1])
    AnnoyEx.add_item(i, 1, [1, 1])
    AnnoyEx.add_item(i, 2, [0, 0])

    assert_in_delta(AnnoyEx.get_distance(i, 0, 1), 1.0 ** 0.5, 0.01)
    assert_in_delta(AnnoyEx.get_distance(i, 1, 2), 2.0 ** 0.5, 0.01)
  end

  test "large index" do
    # Generate pairs of random points where the pair is super close
    f = 10
    i = AnnoyEx.new(f, :euclidean)

    for j <- 0..9999//2 do
      p = normal_list(f)
      x = Enum.map(p, fn pi -> 1 + pi + random_gauss(0, 0.01) end)
      y = Enum.map(p, fn pi -> 1 + pi + random_gauss(0, 0.01) end)
      AnnoyEx.add_item(i, j, x)
      AnnoyEx.add_item(i, j + 1, y)
    end

    AnnoyEx.build(i, 10)

    for j <- 0..9999//2 do
      {res, _} = AnnoyEx.get_nns_by_item(i, j, 2)
      assert res == [j, j + 1]

      {res, _} = AnnoyEx.get_nns_by_item(i, j + 1, 2)
      assert res == [j + 1, j]
    end
  end

  defp check_precision(n, n_trees \\ 10, n_points \\ 10_000, n_rounds \\ 10) do
    founds =
      for _r <- 0..(n_rounds - 1) do
        f = 10
        i = AnnoyEx.new(f, :euclidean)

        for j <- 0..(n_points - 1) do
          p = normal_list(f)
          norm = Enum.sum(Enum.map(p, fn pi -> pi ** 2 end)) ** 0.5
          x = Enum.map(p, fn pi -> pi / norm * j end)
          AnnoyEx.add_item(i, j, x)
        end

        AnnoyEx.build(i, n_trees)

        v = Enum.map(1..f, fn _ -> 0 end)
        {nns, _} = AnnoyEx.get_nns_by_vector(i, v, n)
        assert nns == Enum.sort(nns)

        length(Enum.filter(nns, fn x -> x < n end))
      end

    1.0 * Enum.sum(founds) / (n * n_rounds)
  end

  test "precision_1" do
    check_precision(1)
  end

  test "precision_10" do
    check_precision(10)
  end

  test "precision_100" do
    check_precision(100)
  end

  test "precision_1000" do
    check_precision(1000)
  end

  test "get nns with distances" do
    i = AnnoyEx.new(3, :euclidean)
    AnnoyEx.add_item(i, 0, [0, 0, 2])
    AnnoyEx.add_item(i, 1, [0, 1, 1])
    AnnoyEx.add_item(i, 2, [1, 0, 0])
    AnnoyEx.build(i, 10)

    {l, d} = AnnoyEx.get_nns_by_item(i, 0, 3, -1, true)
    assert l == [0, 1, 2]
    assert_in_delta(Enum.at(d, 0) ** 2, 0.0, 0.01)
    assert_in_delta(Enum.at(d, 1) ** 2, 2.0, 0.01)
    assert_in_delta(Enum.at(d, 2) ** 2, 5.0, 0.01)

    {l, d} = AnnoyEx.get_nns_by_vector(i, [2, 2, 2], 3, -1, true)
    assert l == [1, 0, 2]
    assert_in_delta(Enum.at(d, 0) ** 2, 6.0, 0.01)
    assert_in_delta(Enum.at(d, 1) ** 2, 8.0, 0.01)
    assert_in_delta(Enum.at(d, 2) ** 2, 9.0, 0.01)
  end

  test "include dists" do
    f = 40
    i = AnnoyEx.new(f, :euclidean)
    l1 = normal_list(f)
    l2 = Enum.map(l1, fn x -> -x end)
    AnnoyEx.add_item(i, 0, l1)
    AnnoyEx.add_item(i, 1, l2)
    AnnoyEx.build(i, 10)

    {indices, dists} = AnnoyEx.get_nns_by_item(i, 0, 2, 10, true)
    assert indices == [0, 1]
    assert_in_delta(Enum.at(dists, 0), 0.0, 0.01)
  end

  test "distance consistency" do
    {n, f} = {1000, 3}
    i = AnnoyEx.new(f, :euclidean)

    for j <- 0..(n - 1) do
      AnnoyEx.add_item(i, j, normal_list(f))
    end

    AnnoyEx.build(i, 10)

    for a <- Enum.take_random(0..(n - 1), 100) do
      {indices, dists} = AnnoyEx.get_nns_by_item(i, a, 100)

      for {b, dist} <- Enum.zip(indices, dists) do
        assert_in_delta(dist, AnnoyEx.get_distance(i, a, b), 0.01)

        u = AnnoyEx.get_item_vector(i, a)
        v = AnnoyEx.get_item_vector(i, b)
        v_diff = Enum.zip_reduce(u, v, [], fn x, y, acc -> [x - y | acc] end)

        # self.assertAlmostEqual(dist, numpy.dot(u - v, u - v) ** 0.5)
        assert_in_delta(dist, dot_product(v_diff, v_diff) ** 0.5, 0.01)

        # self.assertAlmostEqual(dist, sum([(x-y)**2 for x, y in zip(u, v)])**0.5)
        assert_in_delta(
          dist,
          (Enum.zip_with(u, v, fn x, y -> (x - y) ** 2 end) |> Enum.sum()) ** 0.5,
          0.01
        )
      end
    end
  end

  test "rounding error" do
    i = AnnoyEx.new(1, :euclidean)
    AnnoyEx.add_item(i, 0, [0.7125930])
    AnnoyEx.add_item(i, 1, [0.7123166])

    assert AnnoyEx.get_distance(i, 0, 1) > 0.0
  end
end
