defmodule AnnoyExMemoryLeakTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  # TODO: this times out.
  # test "get item vector" do
  #   f = 10
  #   i = AnnoyEx.new(f, :euclidean)
  #   AnnoyEx.add_item(i, 0, normal_list(f))

  #   for _j <- 0..100 do
  #     # IO.puts("#{j} ...")
  #     for _ <- 0..1000 * 1000 do
  #       AnnoyEx.get_item_vector(i, 0)
  #     end
  #   end
  # end

  test "get lots of nns" do
    f = 10
    i = AnnoyEx.new(f, :euclidean)
    AnnoyEx.add_item(i, 0, normal_list(f))
    AnnoyEx.build(i, 10)

    for _ <- 0..99 do
      {res, _} = AnnoyEx.get_nns_by_item(i, 0, 999_999_999)
      assert res == [0]
    end
  end

  test "build unbuild" do
    f = 10
    i = AnnoyEx.new(f, :euclidean)

    for j <- 0..999 do
      AnnoyEx.add_item(i, j, normal_list(f))
    end

    AnnoyEx.build(i, 10)

    for _ <- 0..99 do
      AnnoyEx.unbuild(i)
      AnnoyEx.build(i, 10)
    end

    assert AnnoyEx.get_n_items(i) == 1000
  end
end
