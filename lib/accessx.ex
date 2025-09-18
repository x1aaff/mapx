defmodule AccessX do
  def key_find(keys, default \\ nil) do
    fn
      :get, data, next ->
        next.(MapX.get_find(data, keys, default))

      :get_and_update, data, next ->
        {key, value} = MapX.get_find_key_value(data, keys, default)

        default? = key == :"$default"
        key = if default?, do: List.first(keys), else: key

        case next.(value) do
          {get, update} -> {get, Map.put(data, key, update)}
          :pop -> {value, Map.delete(data, key)}
        end
    end
  end

  # MARK: introduced Elixir 1.19.0

  def values do
    &values/3
  end

  defp values(:get, data = %{}, next) do
    Enum.map(data, fn {_key, value} -> next.(value) end)
  end

  defp values(:get_and_update, data = %{}, next) do
    {reverse_gets, updated_data} =
      Enum.reduce(data, {[], %{}}, fn {key, value}, {gets, data_acc} ->
        case next.(value) do
          {get, update} -> {[get | gets], Map.put(data_acc, key, update)}
          :pop -> {[value | gets], data_acc}
        end
      end)

    {Enum.reverse(reverse_gets), updated_data}
  end

  defp values(op, data = [], next) do
    values_keyword(op, data, next)
  end

  defp values(op, data = [{key, _value} | _tail], next) when is_atom(key) do
    values_keyword(op, data, next)
  end

  defp values(_op, data, _next) do
    raise "Access.values/0 expected a map or a keyword list, got: #{inspect(data)}"
  end

  defp values_keyword(:get, data, next) do
    Enum.map(data, fn {key, value} when is_atom(key) -> next.(value) end)
  end

  defp values_keyword(:get_and_update, data, next) do
    {reverse_gets, reverse_updated_data} =
      Enum.reduce(data, {[], []}, fn {key, value}, {gets, data_acc} when is_atom(key) ->
        case next.(value) do
          {get, update} -> {[get | gets], [{key, update} | data_acc]}
          :pop -> {[value | gets], data_acc}
        end
      end)

    {Enum.reverse(reverse_gets), Enum.reverse(reverse_updated_data)}
  end
end
