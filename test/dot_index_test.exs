defmodule AnnoyExDotIndexTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  test "get_nns_by_vector" do
    i = AnnoyEx.new(2, :dot)
    AnnoyEx.add_item(i, 0, [2, 2])
    AnnoyEx.add_item(i, 1, [3, 2])
    AnnoyEx.add_item(i, 2, [3, 3])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 4], 3)
    assert res == [2, 1, 0]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [1, 1], 3)
    assert res == [2, 1, 0]

    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 2], 3)
    assert res == [2, 1, 0]
  end

  test "get_nns_by_item" do
    i = AnnoyEx.new(2, :dot)
    AnnoyEx.add_item(i, 0, [2, 2])
    AnnoyEx.add_item(i, 1, [3, 2])
    AnnoyEx.add_item(i, 2, [3, 3])
    AnnoyEx.build(i, 10)

    {res, _} = AnnoyEx.get_nns_by_item(i, 0, 3)
    assert res == [2, 1, 0]

    {res, _} = AnnoyEx.get_nns_by_item(i, 2, 3)
    assert res == [2, 1, 0]
  end

  test "dist" do
    i = AnnoyEx.new(2, :dot)
    AnnoyEx.add_item(i, 0, [0, 1])
    AnnoyEx.add_item(i, 1, [1, 1])
    AnnoyEx.add_item(i, 2, [0, 0])

    assert_in_delta(AnnoyEx.get_distance(i, 0, 1), 1.0, 0.01)
    assert_in_delta(AnnoyEx.get_distance(i, 1, 2), 0.0, 0.01)
  end

  # def recall_at(self, n, n_trees=10, n_points=1000, n_rounds=5):
  #     # the best movie/variable name
  #     total_recall = 0.

  #     for r in range(n_rounds):
  #         # create random points at distance x
  #         f = 10
  #         idx = AnnoyIndex(f, 'dot')

  #         data = numpy.array([
  #             [random.gauss(0, 1) for z in range(f)]
  #             for j in range(n_points)
  #         ])

  #         expected_results = [
  #             sorted(
  #                 range(n_points),
  #                 key=lambda j: dot_metric(data[i], data[j])
  #             )[:n]
  #             for i in range(n_points)
  #         ]

  #         for i, vec in enumerate(data):
  #             idx.add_item(i, vec)

  #         idx.build(n_trees)

  #         for i in range(n_points):
  #             nns = idx.get_nns_by_vector(data[i], n)
  #             total_recall += recall(nns, expected_results[i])

  #     return total_recall / float(n_rounds * n_points)

  # def test_recall_at_10(self):
  #     value = self.recall_at(10)
  #     self.assertGreaterEqual(value, 0.65)

  # def test_recall_at_100(self):
  #     value = self.recall_at(100)
  #     self.assertGreaterEqual(value, 0.95)

  # def test_recall_at_1000(self):
  #     value = self.recall_at(1000)
  #     self.assertGreaterEqual(value, 0.99)

  # def test_recall_at_1000_fewer_trees(self):
  #     value = self.recall_at(1000, n_trees=4)
  #     self.assertGreaterEqual(value, 0.99)

  test "get nns with distances" do
    f = 3
    i = AnnoyEx.new(f, :dot)
    AnnoyEx.add_item(i, 0, [0, 0, 2])
    AnnoyEx.add_item(i, 1, [0, 1, 1])
    AnnoyEx.add_item(i, 2, [1, 0, 0])
    AnnoyEx.build(i, 10)

    {l, d} = AnnoyEx.get_nns_by_item(i, 0, 3, -1, true)
    assert l == [0, 1, 2]
    assert_in_delta(Enum.at(d, 0), 4.0, 0.01)
    assert_in_delta(Enum.at(d, 1), 2.0, 0.01)
    assert_in_delta(Enum.at(d, 2), 0.0, 0.01)

    {l, d} = AnnoyEx.get_nns_by_vector(i, [2, 2, 2], 3, -1, true)
    assert l == [0, 1, 2]
    assert_in_delta(Enum.at(d, 0), 4.0, 0.01)
    assert_in_delta(Enum.at(d, 1), 4.0, 0.01)
    assert_in_delta(Enum.at(d, 2), 2.0, 0.01)
  end

  test "include dists" do
    f = 40
    i = AnnoyEx.new(f, :dot)
    l1 = normal_list(f)
    l2 = Enum.map(l1, fn x -> -x end)
    AnnoyEx.add_item(i, 0, l1)
    AnnoyEx.add_item(i, 1, l2)
    AnnoyEx.build(i, 10)

    {indices, dists} = AnnoyEx.get_nns_by_item(i, 0, 2, 10, true)
    assert indices == [0, 1]
    assert_in_delta(Enum.at(dists, 0), dot_product(l1, l1), 0.01)
  end

  test "distance consistency" do
    {n, f} = {1000, 3}
    i = AnnoyEx.new(f, :dot)

    for j <- 0..(n - 1) do
      AnnoyEx.add_item(i, j, normal_list(f))
    end

    AnnoyEx.build(i, 10)

    for a <- Enum.take_random(0..(n - 1), 100) do
      {indices, dists} = AnnoyEx.get_nns_by_item(i, a, 100, -1, true)

      for {b, dist} <- Enum.zip(indices, dists) do
        dp = dot_product(AnnoyEx.get_item_vector(i, a), AnnoyEx.get_item_vector(i, b))
        assert_in_delta(dist, dp, 0.01)
        assert_in_delta(dist, AnnoyEx.get_distance(i, a, b), 0.01)
      end
    end
  end
end
