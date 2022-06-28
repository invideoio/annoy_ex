ExUnit.start()

defmodule AnnoyTestHelper do
  def normal_list(f) do
    last = f - 1
    Enum.map(0..last, fn _ -> :rand.normal(0, 1) end)
  end

  def random_gauss(mu \\ 0, sigma \\ 1) do
    {n, _next} = Random.gauss(mu, sigma)
    n
  end

  def dot_product(a, b) when length(a) == length(b), do: dot_product(a, b, 0)

  def dot_product(_, _) do
    raise ArgumentError, message: "Vectors must have the same length."
  end

  defp dot_product([], [], product), do: product
  defp dot_product([h1 | t1], [h2 | t2], product), do: dot_product(t1, t2, product + h1 * h2)
end
