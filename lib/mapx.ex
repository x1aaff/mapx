defmodule MapX do
  @moduledoc """
  Module extending Maps operations
  """

  @doc """
  Replaces a key while preserving value if present
  """
  def replace_key(map, key, replacement) do
    case :maps.take(key, map) do
      {value, map} -> :maps.put(replacement, value, map)
      :error -> map
    end
  end

  @doc """
  Like `replace_key/3` but raises `KeyError` if key missing
  """
  def replace_key!(map, key, replacement) do
    case :maps.take(key, map) do
      {value, map} -> :maps.put(replacement, value, map)
      :error -> raise KeyError, key: key, term: map
    end
  end

  @doc """
  Gets value of first existing key in list, else `default`
  """
  def get_find(map, keys, default \\ nil)

  def get_find(_map, [], default) do
    default
  end

  def get_find(map, [key | rest], default) do
    case map do
      %{^key => value} -> value
      %{} -> get_find(map, rest, default)
    end
  end

  def get_find(map, key, default) do
    get_find(map, [key], default)
  end

  @doc """
  Puts value under `key` where value is computed from current map
  """
  def put_with(map, key, fun) when is_function(fun, 1) do
    Map.put(map, key, fun.(map))
  end

  @doc """
  Conditionally puts `value` under `key` (`condition` is boolean or function)
  """
  def put_if(map, key, value, condition \\ true)

  def put_if(map, key, value, condition) when is_boolean(condition) do
    if condition do
      Map.put(map, key, value)
    else
      map
    end
  end

  def put_if(map, key, value, condition) when is_function(condition, 1) do
    if condition.(%{map: map, key: key, value: value}) do
      Map.put(map, key, value)
    else
      map
    end
  end

  @doc """
  Puts `value` under `key` only if value is not nil
  """
  def put_safe(map, key, value) do
    put_if(map, key, value, not is_nil(value))
  end

  @doc """
  Conditionally updates existing `value` under `key` (raises if missing)
  """
  def update_if!(map, key, fun, condition \\ true)

  def update_if!(map, key, fun, condition) when is_boolean(condition) do
    if condition do
      Map.update!(map, key, fun)
    else
      map
    end
  end

  def update_if!(map, key, fun, condition) when is_function(condition, 1) do
    current = Map.fetch!(map, key)

    if condition.(%{map: map, key: key, current: current}) do
      %{map | key => fun.(current)}
    else
      map
    end
  end

  def update_if!(map, key, fun, condition) when is_function(condition, 2) do
    current = Map.fetch!(map, key)
    result = fun.(current)

    if condition.(%{map: map, key: key, current: current}, result) do
      %{map | key => result}
    else
      map
    end
  end

  @doc """
  Updates value under `key` with initial `{:initial, initial}` value or
  default `{:default, default}` if missing
  """
  def update(map, key, resolve \\ {:default, nil}, fun)

  def update(map, key, {:initial, initial}, fun) when is_function(fun, 1) do
    case map do
      %{^key => value} ->
        %{map | key => fun.(value)}

      %{} ->
        Map.put(map, key, fun.(initial))

      other ->
        :erlang.error({:badmap, other})
    end
  end

  def update(map, key, {:default, default}, fun) when is_function(fun, 1) do
    Map.update(map, key, default, fun)
  end

  @doc """
  Applies function to all values in map
  """
  def update_many(map, fun) when is_function(fun, 1) do
    map
    |> Map.to_list()
    |> update_in([Access.all()], &fun.(&1))
    |> Enum.into(%{})
  end

  @doc """
  Checks if map contains all given keys
  """
  def has_all_keys?(map, keys)

  def has_all_keys?(_map, []) do
    true
  end

  def has_all_keys?(map, [key | rest]) do
    case map do
      %{^key => _value} -> has_all_keys?(map, rest)
      %{} -> false
    end
  end

  @doc """
  Merges map with function-generated map
  """
  def merge_from(map1, map2_fun) when is_function(map2_fun, 1) do
    Map.merge(map1, map2_fun.(map1))
  end

  @doc """
  Like `merge_from/2` with custom merge function
  """
  def merge_from(map1, map2_fun, merge_fun) when is_function(map2_fun, 1) do
    Map.merge(map1, map2_fun.(map1), merge_fun)
  end

  @doc """
  Merges maps, using value functions from second map
  """
  def merge_update(map1, map2) do
    Map.merge(map1, map2, fn
      _k, v1, f2 when is_function(f2, 1) -> f2.(v1)
      _k, _v1, v2 -> v2
    end)
  end
end
