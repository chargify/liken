defmodule Liken do
  defmodule Fuzzy do
    defstruct expected: nil
  end

  def like?(actual, expected) do
    compare(actual, like?(expected), [])
  end

  def like?(expected) do
    %Fuzzy{expected: expected}
  end

  defp compare(actual, %Fuzzy{expected: expected}, path) do
    fuzzy_compare(actual, expected, path) or fail_fuzzy!(actual, expected, path)
  end

  defp compare(actual, expected, path) do
    actual == expected or fail_exact!(actual, expected, path)
  end

  # Like this Regex?
  defp fuzzy_compare(actual, %Regex{} = regex, _path) do
    String.match?(actual, regex)
  end

  # Like this Struct?
  defp fuzzy_compare(actual, %{__struct__: expected_type} = struct, path) do
    actual.__struct__ == expected_type &&
      compare(struct_to_map(actual), like?(struct_to_map(struct)), path)
  end

  # Like this Map?
  defp fuzzy_compare(actual, expected, path) when is_map(expected) do
    Enum.all?(expected, fn({key, value}) ->
      compare(actual[key], value, path ++ ["Map[#{key}]"])
    end)
  end

  # TODO: Like this List?
  # Need to see if everything from expected matches something in actual.  After a match
  # is made, the element needs to be removed from expected, because we don't want to match
  # the same thing multiple times.  Also need to handle path updates...
  defp fuzzy_compare(_actual, expected, _path) when is_list(expected) do
    raise "TODO"
  end

  # Like this Sring?
  defp fuzzy_compare(actual, expected, _path) when is_binary(expected) do
    String.contains?(actual, expected)
  end

  # Catch all
  defp fuzzy_compare(actual, expected, _path) do
    actual == expected
  end

  # Turns a Struct into a Map while removing all keys with nil values.
  #
  # This is necessary since the "expected" map should match when it is a
  # sparse subset of the actual, and `Map.from_struct` ALWAYS includes all
  # keys from the struct, which affects our ability to do a sparse match.
  # See notes on "Sparse matching structs" in the docs for `like?/2`.
  defp struct_to_map(struct) do
    map = struct
    |> Map.from_struct
    |> Enum.filter(fn({_, val}) -> val end)
    map
  end

  defp fail_fuzzy!(actual, expected, path) do
    raise ExUnit.AssertionError, message: """
    Actual value was not like Expected value:
    #{shared_fail_message(actual, expected, path)}
    """
  end

  defp fail_exact!(actual, expected, path) do
    raise ExUnit.AssertionError, message: """
    Actual value was not an exact match for Expected value: #{shared_fail_message(actual, expected, path)}
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
