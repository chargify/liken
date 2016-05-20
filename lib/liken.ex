defmodule Liken do
  defmodule Fuzzy do
    defstruct expected: nil, struct: nil
  end

  @doc """
  must_contain/2 is used in an assert:

      assert actual |> like?(expected)
  """
  def must_contain(actual, expected) do
    compare(actual, includes?(expected), [])
  end

  @doc """
  must_contain/3 allows for top-level fuzzy matching of
  a struct, without requiring all the keys to be specified in the expected
  """
  def must_contain(actual, struct, map) do
    compare(actual, includes?(struct, map), [])
  end

  @doc """
  like/1
  """
  def includes?(expected) do
    %Fuzzy{expected: expected}
  end

  @doc """
  like/2

  Performs a fuzzy match on a struct.

  Because a Struct auto-nils all non-provided fields,
  if you expect to match only CERTAIN fields, you can not
  pass in a struct directly to like/1.  Instead, you pass the struct
  module's name and a map.

  e.g. Don't do:

      # if MyStruct has fields a & b:
      includes?(%MyStruct{a: 1})
      # This won't match %MyStruct{a: 1, b: 1}, because b: nil is implied

  Instead:

      includes?(MyStruct, %{a: 1})
  """
  def includes?(struct, expected) when is_atom(struct) do
    %Fuzzy{struct: struct, expected: expected}
  end

  defp compare(actual, %Fuzzy{} = expected, path) do
    fuzzy_compare(actual, expected, path) or fail_fuzzy!(actual, expected, path)
  end

  defp compare(actual, expected, path) do
    actual == expected or fail_exact!(actual, expected, path)
  end

  # Like this Regex?
  defp fuzzy_compare(actual, %Fuzzy{expected: %Regex{} = regex}, _path) do
    String.match?(actual, regex)
  end

  # Exact match on a struct
  #
  # We want to support passing a struct in directly.
  # And we still want to recursively inspect the keys
  # But this approach will require every key to match (including nils)
  defp fuzzy_compare(actual, %Fuzzy{expected: %{__struct__: struct}=expected}, path) when is_map(actual) do
    actual.__struct__ == struct &&
      Map.from_struct(expected) |> Enum.all?(fn({key, value}) ->
        compare(Map.get(actual, key), value, path ++ ["#{struct}[#{inspect key}]"])
      end)
  end

  # Like this Struct?
  defp fuzzy_compare(actual, %Fuzzy{expected: expected, struct: struct}, path) when not is_nil(struct) do
    actual.__struct__ == struct &&
      compare(Map.from_struct(actual), includes?(expected), path)
  end

  # Like this Map?
  defp fuzzy_compare(actual, %Fuzzy{expected: expected}, path) when is_map(expected) and is_map(actual) do
    Enum.all?(expected, fn({key, value}) ->
      compare(Map.get(actual, key), value, path ++ ["Map[#{inspect key}]"])
    end)
  end

  # There are lots of ways to "fuzzy" match a list:  Contains?  Subset?  Sublist?  Ordered?  Unordered?
  #
  # Liken defines a "fuzzy" match on a list to be:  all elements of expected are contained
  # inside actual in the same order.  Actual may have MORE elements, interspersed anywhere (before, after, in-between)
  #
  #
  defp fuzzy_compare(actual, %Fuzzy{expected: expected}, path) when is_list(expected) do
    fuzzy_list_compare(actual, expected, path)
  end

  # Like this String?
  defp fuzzy_compare(actual, %Fuzzy{expected: expected}, _path) when is_binary(expected) do
    String.contains?(actual, expected)
  end

  # Catch all
  defp fuzzy_compare(actual, %Fuzzy{expected: expected}, _path) do
    actual == expected
  end

  defp fuzzy_compare(actual, expected, _path) do
    actual == expected
  end

  defp fuzzy_list_compare([], [], _path), do: true
  # We've run out of expecteds, meaning we found all expecteds that we wanted.  That's a good thing
  defp fuzzy_list_compare(list, [], _path), do: true
  defp fuzzy_list_compare([], list, _path), do: false

  defp fuzzy_list_compare([ah|at] = actual, [eh|et] = expected, path) do
    if fuzzy_compare(ah, eh, path) do
      # The two elements match, so move on to the next two
      fuzzy_list_compare(at, et, path)
    else
      # The expected element wasn't there, so move forward to the next actual and see
      # if that's the right one
      fuzzy_list_compare(at, expected, path)
    end
  end

  defp fail_fuzzy!(actual, %Fuzzy{expected: expected}, path) do
    raise ExUnit.AssertionError, message: """
    Actual value was not like Expected value:
    #{shared_fail_message(actual, expected, path)}
    """
  end

  defp fail_exact!(actual, expected, path) do
    raise ExUnit.AssertionError, message: """
    Actual value was not an exact match for Expected value:
    #{shared_fail_message(actual, expected, path)}
    """
  end

  defp shared_fail_message(actual, expected, path) do
    """
    #{printed_path(path)}
    Actual:
    #{inspect actual}

    Expected:
    #{inspect expected}
    """
  end

  defp printed_path(list) do
    if length(list) > 0 do
      """

      At:
      #{Enum.join(list, "/")}
      """
    else
      nil
    end
  end
end
