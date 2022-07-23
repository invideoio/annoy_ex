defmodule AnnoyExHolesTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  test "random holes" do
    f = 10
    index = AnnoyEx.new(f, :angular)
    # leave holes
    valid_indices = Enum.take_random(0..1999, 1000)

    for i <- valid_indices do
      v = normal_list(f)
      AnnoyEx.add_item(index, i, v)
    end

    AnnoyEx.build(index, 10)

    for i <- valid_indices do
      {js, _} = AnnoyEx.get_nns_by_item(index, i, 10000)

      assert Enum.all?(js, fn j -> j in valid_indices end)
    end

    for _i <- 0..999 do
      v = normal_list(f)
      {js, _} = AnnoyEx.get_nns_by_vector(index, v, 10000)

      assert Enum.all?(js, fn j -> j in valid_indices end)
    end
  end

  defp test_holes_base(n, f \\ 100, base_i \\ 100_000) do
    annoy = AnnoyEx.new(f, :angular)

    for i <- 0..(n - 1) do
      AnnoyEx.add_item(annoy, base_i + i, normal_list(f))
    end

    AnnoyEx.build(annoy, 100)
    {res, _} = AnnoyEx.get_nns_by_item(annoy, base_i, n)
    assert MapSet.new(res) == Enum.map(0..(n - 1), fn i -> base_i + i end) |> MapSet.new()
  end

  test "root one child" do
    test_holes_base(1)
  end

  test "root two children" do
    test_holes_base(2)
  end

  test "root some children" do
    test_holes_base(10)
  end

  test "root many children" do
    test_holes_base(1000)
  end
end
