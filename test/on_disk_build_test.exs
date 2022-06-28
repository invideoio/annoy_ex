defmodule AnnoyExOnDiskTest do
  use ExUnit.Case, async: true

  setup_all do
    File.rm(filename())

    :ok
  end

  test "on_disk_build/1" do
    f = 2
    i = AnnoyEx.new(f, :euclidean)

    res = AnnoyEx.on_disk_build(i, filename())
    assert res == :ok

    AnnoyEx.add_item(i, 0, [2, 2])
    AnnoyEx.add_item(i, 1, [3, 2])
    AnnoyEx.add_item(i, 2, [3, 3])
    AnnoyEx.build(i, 10)

    check_nns(i)

    res = AnnoyEx.unload(i)
    assert res == :ok

    res = AnnoyEx.load(i, filename())
    assert res == :ok

    check_nns(i)

    j = AnnoyEx.new(f, :euclidean)
    res = AnnoyEx.load(j, filename())
    assert res == :ok

    check_nns(j)
  end

  defp filename(), do: Path.join(System.tmp_dir!(), "on_disk.ann")

  defp check_nns(i) do
    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 4], 3)
    assert res == [2, 1, 0]
    {res, _} = AnnoyEx.get_nns_by_vector(i, [1, 1], 3)
    assert res == [0, 1, 2]
    {res, _} = AnnoyEx.get_nns_by_vector(i, [4, 2], 3)
    assert res == [1, 2, 0]
  end
end
