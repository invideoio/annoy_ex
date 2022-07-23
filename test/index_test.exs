defmodule AnnoyExIndexTest do
  use ExUnit.Case, async: true
  import AnnoyTestHelper

  test "not found tree" do
    i = AnnoyEx.new(10, :angular)
    {:err, msg} = AnnoyEx.load(i, "nonexists.tree")
    assert msg
  end

  test "binary compatbility" do
    i = AnnoyEx.new(10, :angular)
    AnnoyEx.load(i, "test/test.tree")
    {res, _} = AnnoyEx.get_nns_by_item(i, 0, 10)
    assert res == [0, 85, 42, 11, 54, 38, 53, 66, 19, 31]
  end

  test "load unload" do
    i = AnnoyEx.new(10, :angular)

    for _ <- 1..100_000 do
      AnnoyEx.load(i, "test/test.tree")
      AnnoyEx.unload(i)
    end
  end

  test "construct load destruct" do
    for _ <- 0..99_999 do
      i = AnnoyEx.new(10, :angular)
      AnnoyEx.load(i, "test/test.tree")
    end
  end

  test "construct_destruct" do
    for _ <- 1..100_000 do
      i = AnnoyEx.new(10, :angular)
      AnnoyEx.add_item(i, 1000, normal_list(10))
    end
  end

  @tag :tmp_dir
  test "save_twice", %{tmp_dir: tmp_dir} do
    t = AnnoyEx.new(10, :angular)

    for i <- 0..99 do
      AnnoyEx.add_item(t, i, normal_list(10))
    end

    AnnoyEx.build(t, 10)
    AnnoyEx.save(t, Path.join(tmp_dir, "t1.ann"))
    AnnoyEx.save(t, Path.join(tmp_dir, "t2.ann"))
  end

  @tag :tmp_dir
  test "load save", %{tmp_dir: tmp_dir} do
    i = AnnoyEx.new(10, :angular)
    AnnoyEx.load(i, "test/test.tree")
    u = AnnoyEx.get_item_vector(i, 99)
    AnnoyEx.save(i, Path.join(tmp_dir, "i.tree"))
    v = AnnoyEx.get_item_vector(i, 99)
    assert u == v

    j_tree = Path.join(tmp_dir, "j.tree")
    k_tree = Path.join(tmp_dir, "k.tree")

    j = AnnoyEx.new(10, :angular)
    AnnoyEx.load(j, "test/test.tree")
    w = AnnoyEx.get_item_vector(i, 99)
    assert u == w
    # Ensure specifying if prefault is allowed does not impact result
    AnnoyEx.save(j, j_tree, true)
    k = AnnoyEx.new(10, :angular)
    AnnoyEx.load(k, j_tree, true)
    x = AnnoyEx.get_item_vector(k, 99)
    assert u == x
    AnnoyEx.save(k, k_tree, false)

    l = AnnoyEx.new(10, :angular)
    AnnoyEx.load(l, k_tree, false)
    y = AnnoyEx.get_item_vector(l, 99)
    assert u == y
  end

  test "save without build" do
    t = AnnoyEx.new(10, :angular)

    for i <- 0..99 do
      AnnoyEx.add_item(t, i, normal_list(10))
    end

    {:err, msg} = AnnoyEx.save(t, "x.tree")
    assert msg
  end

  test "unbuild with loaded tree" do
    i = AnnoyEx.new(10, :angular)
    :ok = AnnoyEx.load(i, "test/test.tree")
    {:err, msg} = AnnoyEx.unbuild(i)
    assert msg
  end

  test "set_seed" do
    i = AnnoyEx.new(10, :angular)
    AnnoyEx.load(i, "test/test.tree")
    res = AnnoyEx.set_seed(i, 42)

    assert res == :ok
  end

  test "unknown distance" do
    assert_raise(ArgumentError, fn -> AnnoyEx.new(10, :banana) end)
  end

  @tag :tmp_dir
  test "item vector after save", %{tmp_dir: tmp_dir} do
    a = AnnoyEx.new(3, :angular)
    AnnoyEx.verbose(a, true)
    AnnoyEx.add_item(a, 1, [1, 0, 0])
    AnnoyEx.add_item(a, 2, [0, 1, 0])
    AnnoyEx.add_item(a, 3, [0, 0, 1])
    AnnoyEx.build(a, -1)

    assert AnnoyEx.get_n_items(a) == 4
    assert AnnoyEx.get_item_vector(a, 3) == [0, 0, 1]
    {res, _} = AnnoyEx.get_nns_by_item(a, 1, 999)
    assert Enum.uniq(res) == [1, 2, 3]

    AnnoyEx.save(a, Path.join(tmp_dir, "something.annoy"))
    assert AnnoyEx.get_n_items(a) == 4
    assert AnnoyEx.get_item_vector(a, 3) == [0, 0, 1]
    {res, _} = AnnoyEx.get_nns_by_item(a, 1, 999)
    assert Enum.uniq(res) == [1, 2, 3]
  end

  test "prefault" do
    i = AnnoyEx.new(10, :angular)
    AnnoyEx.load(i, "test/test.tree", true)
    {res, _} = AnnoyEx.get_nns_by_item(i, 0, 10)
    assert res == [0, 85, 42, 11, 54, 38, 53, 66, 19, 31]
  end

  test "fail save" do
    t = AnnoyEx.new(40, :angular)
    {:err, msg} = AnnoyEx.save(t, '')
    assert msg
  end

  @tag :tmp_dir
  test "overwrite index", %{tmp_dir: tmp_dir} do
    f = 40

    # Build the initial index
    t = AnnoyEx.new(f, :angular)

    for i <- 0..999 do
      v = normal_list(f)
      AnnoyEx.add_item(t, i, v)
    end

    AnnoyEx.build(t, 10)
    AnnoyEx.save(t, Path.join(tmp_dir, "test.ann"))

    # Load index file
    t2 = AnnoyEx.new(f, :angular)
    AnnoyEx.load(t2, Path.join(tmp_dir, "test.ann"))

    # Overwrite index file
    t3 = AnnoyEx.new(f, :angular)

    for i <- 0..499 do
      v = normal_list(f)
      AnnoyEx.add_item(t3, i, v)
    end

    AnnoyEx.build(t3, 10)

    AnnoyEx.save(t3, Path.join(tmp_dir, "test.ann"))
    # Get nearest neighbors
    v = normal_list(f)
    # Should not crash
    AnnoyEx.get_nns_by_vector(t3, v, 1000)
  end

  test "get_n_trees" do
    i = AnnoyEx.new(10, :angular)
    AnnoyEx.load(i, "test/test.tree")
    assert AnnoyEx.get_n_trees(i) == 10
  end

  test "write failed" do
    f = 40
    t = AnnoyEx.new(f, :angular)
    AnnoyEx.verbose(t, true)

    for i <- 0..999 do
      v = normal_list(f)
      AnnoyEx.add_item(t, i, v)
    end

    AnnoyEx.build(t, 10)

    {:err, msg} = AnnoyEx.save(t, "/x/y/z.annoy")
    assert msg
  end

  @tag :tmp_dir
  test "dimension mismatch", %{tmp_dir: tmp_dir} do
    filepath = Path.join(tmp_dir, "test.annoy")
    t = AnnoyEx.new(100, :angular)

    for i <- 0..999 do
      AnnoyEx.add_item(t, i, normal_list(100))
    end

    AnnoyEx.build(t, 10)
    AnnoyEx.save(t, filepath)

    u = AnnoyEx.new(200, :angular)
    {:err, msg} = AnnoyEx.load(u, filepath)
    assert msg

    u = AnnoyEx.new(50, :angular)
    {:err, msg} = AnnoyEx.load(u, filepath)
    assert msg
  end

  @tag :tmp_dir
  test "add after save", %{tmp_dir: tmp_dir} do
    t = AnnoyEx.new(100, :angular)

    for i <- 0..999 do
      AnnoyEx.add_item(t, i, normal_list(100))
    end

    AnnoyEx.build(t, 10)
    AnnoyEx.save(t, Path.join(tmp_dir, "test.annoy"))

    v = normal_list(100)
    {:err, msg} = AnnoyEx.add_item(t, 999, v)
    assert msg
  end

  test "build twice" do
    t = AnnoyEx.new(100, :angular)

    for i <- 0..999 do
      AnnoyEx.add_item(t, i, normal_list(100))
    end

    AnnoyEx.build(t, 10)
    {:err, msg} = AnnoyEx.build(t, 10)
    assert msg
  end

  @tag :tmp_dir
  test "very large index", %{tmp_dir: tmp_dir} do
    f = 3
    dangerous_size = :math.pow(2, 31)
    size_per_vector = 4 * (f + 3)
    n_vectors = floor(dangerous_size / size_per_vector)

    m = AnnoyEx.new(3, :angular)
    AnnoyEx.verbose(m, true)

    for i <- 0..99 do
      AnnoyEx.add_item(m, n_vectors + i, normal_list(f))
    end

    n_trees = 10
    AnnoyEx.build(m, n_trees)
    path = Path.join(tmp_dir, "test_big.annoy")
    # Raises on Windows
    AnnoyEx.save(m, path)

    # Sanity check size of index
    {:ok, stat} = File.stat(path)
    assert stat.size >= dangerous_size
    # self.assertGreaterEqual(os.path.getsize(path), dangerous_size)
    assert stat.size < dangerous_size + 100_000
    # self.assertLess(os.path.getsize(path), dangerous_size + 100e3)

    # Sanity check number of trees
    assert AnnoyEx.get_n_trees(m) == n_trees
  end
end
