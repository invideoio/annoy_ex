defmodule AnnoyExExampleTest do
  use ExUnit.Case, async: true

  test "simple test" do
    a = AnnoyEx.new(3, :angular)

    AnnoyEx.add_item(a, 0, [1, 0, 0])
    AnnoyEx.add_item(a, 1, [0, 1, 0])
    AnnoyEx.add_item(a, 2, [0, 0, 1])
    AnnoyEx.build(a, -1)

    {results, _} = AnnoyEx.get_nns_by_item(a, 0, 100)
    assert results == [0, 1, 2]

    {results, _} = AnnoyEx.get_nns_by_vector(a, [1.0, 0.5, 0.5], 100)
    assert results == [0, 1, 2]
  end

  test "mmap test" do
    test_file = Path.join(System.tmp_dir!(), "test.tree")
    a = AnnoyEx.new(3, :angular)

    AnnoyEx.add_item(a, 0, [1, 0, 0])
    AnnoyEx.add_item(a, 1, [0, 1, 0])
    AnnoyEx.add_item(a, 2, [0, 0, 1])
    AnnoyEx.build(a, -1)

    AnnoyEx.save(a, test_file)

    b = AnnoyEx.new(3)
    AnnoyEx.load(b, test_file)

    {results, _} = AnnoyEx.get_nns_by_item(a, 0, 100)
    assert results == [0, 1, 2]

    {results, _} = AnnoyEx.get_nns_by_vector(a, [1.0, 0.5, 0.5], 100)
    assert results == [0, 1, 2]
  end
end
