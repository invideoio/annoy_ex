defmodule AnnoyExAngularIndexTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  defp check_precision(n, n_trees \\ 10, n_points \\ 10000, n_rounds \\ 10, search_k \\ 100_000) do
    founds =
      for _r <- 0..(n_rounds - 1) do
        f = 10
        i = AnnoyEx.new(f, :angular)

        for j <- 0..(n_points - 1) do
          p = normal_list(f - 1)
          norm = :math.pow(Enum.sum(Enum.map(p, fn pi -> :math.pow(pi, 2) end)), 0.5)

          x = Enum.map(p, fn pi -> pi / norm * j end) |> List.insert_at(0, 1000)

          AnnoyEx.add_item(i, j, x)
        end

        AnnoyEx.build(i, n_trees)

        v = Enum.map(1..(f - 1), fn _ -> 0 end) |> List.insert_at(0, 1000)
        {nns, _} = AnnoyEx.get_nns_by_vector(i, v, n, search_k)
        assert nns == Enum.sort(nns)

        length(Enum.filter(nns, fn x -> x < n end))
      end

    1.0 * Enum.sum(founds) / (n * n_rounds)
  end

  test "get_nns_by_vector" do
    f = 3
    i = AnnoyEx.new(f, :angular)
    AnnoyEx.add_item(i, 0, [0, 0, 1])
    AnnoyEx.add_item(i, 1, [0, 1, 0])
    AnnoyEx.add_item(i, 2, [1, 0, 0])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_vector(i, [3, 2, 1], 3)
    assert res == [2, 1, 0]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [1, 2, 3], 3)
    assert res == [0, 1, 2]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [2, 0, 1], 3)
    assert res == [2, 0, 1]
  end

  test "get_nns_by_item" do
    f = 3
    i = AnnoyEx.new(f, :angular)
    AnnoyEx.add_item(i, 0, [2, 1, 0])
    AnnoyEx.add_item(i, 1, [1, 2, 0])
    AnnoyEx.add_item(i, 2, [0, 0, 1])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_item(i, 0, 3)
    assert res == [0, 1, 2]

    {res, _} = AnnoyEx.get_nns_by_item(i, 1, 3)
    assert res == [1, 0, 2]

    {res, _} = AnnoyEx.get_nns_by_item(i, 2, 3)
    assert res == [2, 0, 1] || res == [2, 1, 0]
  end

  test "dist" do
    i = AnnoyEx.new(2, :angular)
    AnnoyEx.add_item(i, 0, [0, 1])
    AnnoyEx.add_item(i, 1, [1, 1])

    assert_in_delta(
      AnnoyEx.get_distance(i, 0, 1),
      :math.pow(2 * (1.0 - :math.pow(2, -0.5)), 0.5),
      0.1
    )
  end

  test "dist_2" do
    i = AnnoyEx.new(2, :angular)
    AnnoyEx.add_item(i, 0, [1000, 0])
    AnnoyEx.add_item(i, 1, [10, 0])

    assert_in_delta(AnnoyEx.get_distance(i, 0, 1), 0, 0.01)
  end

  test "dist_3" do
    i = AnnoyEx.new(2, :angular)
    AnnoyEx.add_item(i, 0, [97, 0])
    AnnoyEx.add_item(i, 1, [42, 42])

    dist =
      :math.pow(:math.pow(1.0 - :math.pow(2, -0.5), 2) + :math.pow(:math.pow(2, -0.5), 2), 0.5)

    assert_in_delta(AnnoyEx.get_distance(i, 0, 1), dist, 0.01)
  end

  test "dist_degen" do
    i = AnnoyEx.new(2, :angular)
    AnnoyEx.add_item(i, 0, [1, 0])
    AnnoyEx.add_item(i, 1, [0, 0])

    assert_in_delta(AnnoyEx.get_distance(i, 0, 1), :math.pow(2.0, 0.5), 0.01)
  end

  test "large index" do
    f = 10
    i = AnnoyEx.new(f, :angular)

    for j <- 0..9999//2 do
      p = Enum.map(0..(f - 1), fn _ -> random_gauss() end)
      f1 = :rand.uniform() + 1
      f2 = :rand.uniform() + 1
      x = Enum.map(p, fn pi -> f1 * pi + random_gauss(0, 0.01) end)
      y = Enum.map(p, fn pi -> f2 * pi + random_gauss(0, 0.01) end)
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

  @tag :tmp_dir
  test "load save get item vector", %{tmp_dir: tmp_dir} do
    f = 3
    i = AnnoyEx.new(f, :angular)
    AnnoyEx.add_item(i, 0, [1.1, 2.2, 3.3])
    AnnoyEx.add_item(i, 1, [4.4, 5.5, 6.6])
    AnnoyEx.add_item(i, 2, [7.7, 8.8, 9.9])

    v = AnnoyEx.get_item_vector(i, 0)
    assert_in_delta(Enum.at(v, 0), 1.1, 0.01)
    assert_in_delta(Enum.at(v, 1), 2.2, 0.01)
    assert_in_delta(Enum.at(v, 2), 3.3, 0.01)

    assert AnnoyEx.build(i, 10)
    assert AnnoyEx.save(i, Path.join(tmp_dir, "blah.ann"))

    v = AnnoyEx.get_item_vector(i, 1)
    assert_in_delta(Enum.at(v, 0), 4.4, 0.01)
    assert_in_delta(Enum.at(v, 1), 5.5, 0.01)
    assert_in_delta(Enum.at(v, 2), 6.6, 0.01)

    j = AnnoyEx.new(f, :angular)
    assert AnnoyEx.load(j, Path.join(tmp_dir, "blah.ann"))

    v = AnnoyEx.get_item_vector(i, 2)
    assert_in_delta(Enum.at(v, 0), 7.7, 0.01)
    assert_in_delta(Enum.at(v, 1), 8.8, 0.01)
    assert_in_delta(Enum.at(v, 2), 9.9, 0.01)
  end

  test "get_nns_search_k" do
    i = AnnoyEx.new(3, :angular)
    AnnoyEx.add_item(i, 0, [0, 0, 1])
    AnnoyEx.add_item(i, 1, [0, 1, 0])
    AnnoyEx.add_item(i, 2, [1, 0, 0])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_item(i, 0, 3, 10)
    assert res == [0, 1, 2]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [3, 2, 1], 3, 10)
    assert res == [2, 1, 0]
  end

  test "include dists" do
    f = 40
    i = AnnoyEx.new(f, :angular)

    l1 = normal_list(f)
    l2 = Enum.map(l1, fn x -> -x end)

    AnnoyEx.add_item(i, 0, l1)
    AnnoyEx.add_item(i, 1, l2)
    AnnoyEx.build(i, 10)

    {indices, dists} = AnnoyEx.get_nns_by_item(i, 0, 2, 10, true)
    assert indices == [0, 1]
    assert_in_delta(Enum.at(dists, 0), 0.0, 0.01)
    assert_in_delta(Enum.at(dists, 1), 2.0, 0.01)
  end

  test "include_dists_check_ranges" do
    f = 3
    i = AnnoyEx.new(f, :angular)

    for j <- 0..99999 do
      v = normal_list(f)
      AnnoyEx.add_item(i, j, v)
    end

    AnnoyEx.build(i, 10)
    {_indices, dists} = AnnoyEx.get_nns_by_item(i, 0, 100_000, -1, true)
    assert Enum.max(dists) <= 2.0
    assert_in_delta(Enum.min(dists), 0.0, 0.01)
  end

  test "distance consistency" do
    {n, f} = {1000, 3}
    i = AnnoyEx.new(f, :angular)

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

        u_norm = Enum.map(u, fn x -> x * :math.pow(dot_product(u, u), -0.5) end)
        v_norm = Enum.map(v, fn x -> x * :math.pow(dot_product(v, v), -0.5) end)

        # self.assertAlmostEqual(dist ** 2, numpy.dot(u_norm - v_norm, u_norm - v_norm))
        norm_diff = Enum.zip_reduce(u_norm, v_norm, [], fn x, y, acc -> [x - y | acc] end)
        assert_in_delta(:math.pow(dist, 2), dot_product(norm_diff, norm_diff), 0.01)
        # self.assertAlmostEqual(dist ** 2, sum([(x-y)**2 for x, y in zip(u_norm, v_norm)]))
        assert_in_delta(
          :math.pow(dist, 2),
          Enum.zip_with(u_norm, v_norm, fn x, y -> :math.pow(x - y, 2) end) |> Enum.sum(),
          0.01
        )
      end
    end
  end

  @tag :tmp_dir
  test "only_one_item", %{tmp_dir: tmp_dir} do
    index_file = Path.join(tmp_dir, "foo.idx")

    idx = AnnoyEx.new(100, :angular)
    v = normal_list(100)
    AnnoyEx.add_item(idx, 0, v)
    AnnoyEx.build(idx, 10)
    AnnoyEx.save(idx, index_file)

    idx = AnnoyEx.new(100, :angular)
    AnnoyEx.load(idx, index_file)
    assert AnnoyEx.get_n_items(idx) == 1
    v = normal_list(100)
    {res, _} = AnnoyEx.get_nns_by_vector(idx, v, 50)
    assert res == [0]
  end

  @tag :tmp_dir
  test "no_items", %{tmp_dir: tmp_dir} do
    index_file = Path.join(tmp_dir, "foo.idx")

    idx = AnnoyEx.new(100, :angular)
    AnnoyEx.build(idx, 10)
    AnnoyEx.save(idx, index_file)

    idx = AnnoyEx.new(100, :angular)
    AnnoyEx.load(idx, index_file)
    assert AnnoyEx.get_n_items(idx) == 0
    v = normal_list(100)
    {res, _} = AnnoyEx.get_nns_by_vector(idx, v, 50, -1, false)
    assert res == []
  end

  @tag :tmp_dir
  test "single_vector", %{tmp_dir: tmp_dir} do
    a = AnnoyEx.new(3, :angular)
    AnnoyEx.add_item(a, 0, [1, 0, 0])
    AnnoyEx.build(a, 10)
    AnnoyEx.save(a, Path.join(tmp_dir, "1.ann"))
    {indices, dists} = AnnoyEx.get_nns_by_vector(a, [1, 0, 0], 3, -1, true)
    assert indices == [0]
    assert_in_delta(:math.pow(Enum.at(dists, 0), 2), 0.0, 0.01)
  end
end
