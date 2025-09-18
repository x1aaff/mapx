defmodule EnumX do
  def subset?(enumerable1, enumerable2) do
    MapSet.subset?(MapSet.new(enumerable1), MapSet.new(enumerable2))
  end

  def group_by_nested(enumerable, []) do
    enumerable
  end

  def group_by_nested(enumerable, [funs | rest]) do
    {key_fun, value_fun} =
      case funs do
        {key_fun, value_fun} -> {key_fun, value_fun}
        key_fun -> {key_fun, fn value -> value end}
      end

    enumerable
    |> Enum.group_by(key_fun, value_fun)
    |> Enum.into(%{}, fn {key, values} -> {key, group_by_nested(values, rest)} end)
  end

  def associate_by!(enumerable, key_fun, value_fun \\ fn x -> x end) when is_function(key_fun) do
    enumerable
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn entry, acc ->
      key = key_fun.(entry)
      value = value_fun.(entry)

      case acc do
        %{^key => existing} ->
          raise ArgumentError, "tried to associate by with single value, but under key #{inspect(key)} " <>
            "there are several values [#{inspect(existing)}, #{inspect(value)}] already"

        %{} ->
          Map.put(acc, key, value)
      end
    end)
  end
end
