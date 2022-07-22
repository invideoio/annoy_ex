defmodule AnnoyExManhattanIndexTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  defp check_precision(n, n_trees \\ 10, n_points \\ 10000, n_rounds \\ 10) do
    founds =
      for _r <- 0..(n_rounds - 1) do
        f = 10
        i = AnnoyEx.new(f, :manhattan)

        for j <- 0..(n_points - 1) do
          p = normal_list(f)
          norm = :math.pow(Enum.sum(Enum.map(p, fn pi -> :math.pow(pi, 2) end)), 0.5)
          x = Enum.map(p, fn pi -> pi / norm + j end)
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

  test "get_nns_by_vector" do
    i = AnnoyEx.new(2, :manhattan)
    AnnoyEx.add_item(i, 0, [2, 2])
    AnnoyEx.add_item(i, 1, [3, 2])
    AnnoyEx.add_item(i, 2, [3, 3])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 4], 3)
    assert res == [2, 1, 0]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [1, 1], 3)
    assert res == [0, 1, 2]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [5, 3], 3)
    assert res == [2, 1, 0]
  end

  test "get_nns_by_item" do
    i = AnnoyEx.new(2, :manhattan)
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
    i = AnnoyEx.new(2, :manhattan)
    AnnoyEx.add_item(i, 0, [0, 1])
    AnnoyEx.add_item(i, 1, [1, 1])
    AnnoyEx.add_item(i, 2, [0, 0])
    AnnoyEx.build(i, 10)

    assert_in_delta(AnnoyEx.get_distance(i, 0, 1), 1.0, 0.1)
    assert_in_delta(AnnoyEx.get_distance(i, 1, 2), 2.0, 0.1)
  end

  test "large index" do
    f = 10
    i = AnnoyEx.new(f, :manhattan)

    for j <- 0..9999//2 do
      p = Enum.map(0..(f - 1), fn _ -> random_gauss() end)
      x = Enum.map(p, fn pi -> 1 + pi + random_gauss(0, 0.01) end)
      y = Enum.map(p, fn pi -> 1 + pi + random_gauss(0, 0.01) end)
      AnnoyEx.add_item(i, j, x)
      AnnoyEx.add_item(i, j + 1, y)
    end

    AnnoyEx.build(i, 10)

    for k <- 0..9999//2 do
      {res, _} = AnnoyEx.get_nns_by_item(i, k, 2)
      assert res == [k, k + 1]
      {res, _} = AnnoyEx.get_nns_by_item(i, k + 1, 2)
      assert res == [k + 1, k]
    end
  end

  test "precision_1" do
    assert check_precision(1) >= 0.98
  end

  test "precision_10" do
    assert check_precision(10) >= 0.98
  end

  test "precision_100" do
    assert check_precision(100) >= 0.98
  end

  test "precision_1000" do
    assert check_precision(1000) >= 0.98
  end

  test "get_nns_with_distances" do
    f = 3
    i = AnnoyEx.new(f, :manhattan)
    AnnoyEx.add_item(i, 0, [0, 0, 2])
    AnnoyEx.add_item(i, 1, [0, 1, 1])
    AnnoyEx.add_item(i, 2, [1, 0, 0])
    AnnoyEx.build(i, 10)

    {l, d} = AnnoyEx.get_nns_by_item(i, 0, 3, -1, true)
    assert l == [0, 1, 2]
    assert_in_delta(Enum.at(d, 0), 0.0, 0.01)
    assert_in_delta(Enum.at(d, 1), 2.0, 0.01)
    assert_in_delta(Enum.at(d, 2), 3.0, 0.01)

    {l, d} = AnnoyEx.get_nns_by_vector(i, [2, 2, 1], 3, -1, true)
    assert l == [1, 2, 0]
    assert_in_delta(Enum.at(d, 0), 3.0, 0.01)
    assert_in_delta(Enum.at(d, 1), 4.0, 0.01)
    assert_in_delta(Enum.at(d, 2), 5.0, 0.01)
  end

  test "include dists" do
    f = 40
    i = AnnoyEx.new(f, :manhattan)
    l1 = normal_list(f)
    l2 = Enum.map(l1, fn x -> -x end)

    AnnoyEx.add_item(i, 0, l1)
    AnnoyEx.add_item(i, 1, l2)
    AnnoyEx.build(i, 10)

    {indices, dists} = AnnoyEx.get_nns_by_item(i, 0, 2, 10, true)
    assert indices == [0, 1]
    assert_in_delta(Enum.at(dists, 0), 0.0, 0.01)
  end

  test "test_distance_consistency" do
    {n, f} = {1000, 3}
    i = AnnoyEx.new(f, :manhattan)

    for j <- 0..(n - 1) do
      AnnoyEx.add_item(i, j, normal_list(f))
    end

    AnnoyEx.build(i, 10)

    for a <- Enum.take_random(0..(n - 1), 100) do
      {indices, dists} = AnnoyEx.get_nns_by_item(i, a, 100, -1, true)

      for {b, dist} <- Enum.zip(indices, dists) do
        assert_in_delta(dist, AnnoyEx.get_distance(i, a, b), 0.01)
        #    u = numpy.array(i.get_item_vector(a))
        u = AnnoyEx.get_item_vector(i, a)
        #    v = numpy.array(i.get_item_vector(b))
        v = AnnoyEx.get_item_vector(i, b)
        #    self.assertAlmostEqual(dist, numpy.sum(numpy.fabs(u - v)))
        assert_in_delta(
          dist,
          Enum.zip_reduce(u, v, [], fn x, y, acc -> [abs(x - y) | acc] end) |> Enum.sum(),
          0.01
        )

        #    self.assertAlmostEqual(dist, sum([abs(float(x)-float(y)) for x, y in zip(u, v)]))
        assert_in_delta(
          dist,
          Enum.zip(u, v) |> Enum.map(fn {x, y} -> abs(x * 1.0 - y * 1.0) end) |> Enum.sum(),
          0.01
        )
      end
    end
  end
end
