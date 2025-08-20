# MapX

Extended map operations for Elixir, providing additional utility functions for working with maps.

> [!NOTE]
> No tests. Code can be changed disregard backward compatibility. Use at your own discretion.

## Features

- **Key replacement**: Safely rename keys while preserving values
- **Conditional updates**: Modify maps based on conditions
- **Key discovery**: Find values using fallback keys
- **Batch operations**: Apply transformations to multiple values
- **Smart merging**: Merge maps with dynamic values

## Installation

You can copy any code you need

Or add to your `mix.exs`:
```elixir
def deps do
  [
    {:mapx, git: "https://github.com/x1aaff/mapx.git"}
  ]
end
```

## API Reference

### `replace_key(map, key, replacement)`
Replaces a key while preserving its value. Safe version.
```elixir
MapX.replace_key(%{person: %{name: "Alice"}}, :person, :customer)  
# => %{customer: %{name: "Alice"}}
MapX.replace_key(%{customer: %{name: "Bob"}}, :person, :customer)  
# => %{customer: %{name: "Bob"}} (no change)
```

### `replace_key!(map, key, replacement)`
Replaces a key (raises if key missing)
```elixir
MapX.replace_key!(%{a: 1}, :a, :b)
# => %{b: 1}
MapX.replace_key!(%{a: 1}, :x, :y)
# => raises KeyError
```

### `get_find(map, keys, default \\ nil)`
Gets value of first existing key in list
```elixir
MapX.get_find(%{person: %{name: "Alice"}}, [:customer, :person, :client])
# => %{name: "Alice"}
MapX.get_find(%{a: 1, b: 2}, [:c, :a])
# => 1
MapX.get_find(%{a: 1}, [:x, :y], :none)
# => :none
```

### `put_with(map, key, fun)`
Puts key with value computed from current map
```elixir
%{}
|> Map.put(:price, 100.0)
|> MapX.put_with(:price_discounted, fn p -> p.price * 0.9 end)
# => %{price: 100.0, price_discounted: 90.0}

MapX.put_with(%{count: 5}, :double, fn m -> m.count * 2 end)
# => %{count: 5, double: 10}
```

### `put_if(map, key, value, condition)`
Conditionally puts key-value pair
```elixir
# Condition is boolean
MapX.put_if(%{}, :admin, true, false)  # => %{} (no add)

# Condition is function: fn %{map: _, key: _, value: _} -> ... end
MapX.put_if(%{age: 20}, :adult, true, fn ctx -> ctx.map.age >= 18 end)
# => %{age: 20, adult: true}
MapX.put_if(%{}, "not cool", true, fn ctx -> String.starts_with?(ctx.key, "cool") end)
# => %{}
MapX.put_if(%{}, :list, {1, 2, 3}, fn %{value: v} -> is_list(v) end)
# => %{}
MapX.put_if(%{}, :list, [1, 2, 3], fn %{value: v} -> is_list(v) end)
# => %{list: [1, 2, 3]}
```

### `put_safe(map, key, value)`
Puts key only if value is not nil
```elixir
alice = %{name: "Alice"}
bob = %{age: 25}
MapX.put_safe(%{}, :name, alice[:name])
# => %{name: "Alice"}
MapX.put_safe(%{}, :name, bob[:name])
# => %{}
```

### `update_if!(map, key, fun, condition)`
Conditionally updates existing key
```elixir
# Condition is boolean
MapX.update_if!(%{count: 5}, :count, &(&1 * 2), true)
# => %{count: 10}

# Condition is function: fn %{map: _, key: _, current: _} -> ... end
MapX.update_if!(%{score: 50}, :score, &(&1 + 10), fn ctx -> ctx.current < 100 end)
# => %{score: 60}

# Or condition is function: fn %{map: _, key: _, current: _}, result -> ... end
# idk how make consistent 1-arg ctx and optionally calculate result for checking
# if it is requested, so this is an open question
MapX.update_if!(%{balance: 50}, :balance, &(&1 - 100), fn _ctx, result -> result > 0 end)
# => %{balance: 50}
```

### `update(map, key, resolve, fun)`
Updates key with initial value or default
```elixir
MapX.update(%{a: 1}, :a, {:default, 0}, &(&1 + 1))
# => %{a: 2}
MapX.update(%{}, :a, {:initial, 10}, &(&1 * 2))
# => %{a: 20}
MapX.update(%{}, :list, {:initial, []}, &[:first | &1])
# => %{list: [:first]}
```

### `update_many(map, fun)`
Applies function to all values
```elixir
MapX.update_many(%{a: 1, b: 2}, fn {k, v} -> {k, v * 3} end)
# => %{a: 3, b: 6}
```

### `has_all_keys?(map, keys)`
Checks if map contains all keys
```elixir
MapX.has_all_keys?(%{a: 1, b: 2}, [:a, :b])
# => true
MapX.has_all_keys?(%{a: 1}, [:a, :c])
# => false
```

### `merge_from(map1, map2_fun)`
Merges with dynamically generated map
```elixir
MapX.merge_from(%{a: 1}, fn m -> %{b: m.a * 2} end)
# => %{a: 1, b: 2}

order = %{qty: 5}
fill = 3

order
|> Map.update!(:qty, &(&1 - fill))
|> MapX.merge_from(fn order -> 
  case order do
    %{qty: 0} ->
      %{
        balance: :fully_executed,
        status: :executed
      }

    _ ->
      %{
        balance: :partially_executed,
        smile: ":)"
      }
  end
end)
# => %{balance: :partially_executed, qty: 2, smile: ":)"}
```

### `merge_update(map1, map2)`
Merges maps, applying value functions
```elixir
MapX.merge_update(%{a: 1}, %{a: &(&1 + 1), b: 2})
# => %{a: 2, b: 2}
```

## Why MapX?

- Better pipelining

Contributions or issues are welcome.
