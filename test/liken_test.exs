defmodule LikenTest do
  use ExUnit.Case
  import Liken
  doctest Liken

  test "an Integer is like the same Integer" do
    assert 1 |> like?(1)
  end

  test "an Integer is not like another Integer" do
    func = fn -> like?(1, 2) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    Actual:
    1

    Expected:
    2

    """, func
  end

  test "a Map is like the same Map" do
    this = %{a: %{b: 2}}
    that = %{a: %{b: 2}}

    assert this |> like?(that)
  end

  test "a Map is not like a different Map" do
    func = fn-> like?(%{a: 1}, %{a: 2}) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not exact match for Expected value:

    At:
    Map[:a]

    Actual:
    1

    Expected:
    2

    """, func
  end

  test "a Map is like its subset" do
    this = %{a: 1, b: 2}
    that = %{a: 1}
    blat = %{b: 2}

    assert this |> like?(that)
    assert this |> like?(blat)
  end

  test "a Map is not like its superset" do
    func = fn-> like?(%{a: 1}, %{a: 1, b: 2}) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    At:
    Map[:b]

    Actual:
    nil

    Expected:
    2
    """, func
  end

  test "a Map is not like another Map if their nested structures differ as a subset" do
    func = fn-> like?(%{a: %{b: 2, c: 3}}, %{a: %{b: 2}}) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    At:
    Map[:a]

    Actual:
    %{b: 2, c: 3}

    Expected:
    %{b: 2}
    """, func
  end

  test "a Map with all values as subsets can be like another Map when cascading `like`s are used" do
    this = %{a: %{b: 2, c: 3}}
    that = %{a: like?(%{b: 2})}

    assert this |> like?(that)
  end

  test "a List is like the same list" do
    this = [1, 2, 3]
    that = [1, 2, 3]

    assert this |> like?(that)
  end

  test "a List is like a subset List" do
    this = [1, 2, 3]
    that = [1, 2]

    assert this |> like?(that)
  end

  @tag :pending
  test "a List is not like a superset List" do
    this = [1, 2]
    that = [1, 2, 3]

    refute this |> like?(that)
  end

  test "a String is like the same String" do
    assert "foo" |> like?("foo")
  end

  test "a String is like a substring" do
    assert "foo" |> like?("oo")
  end

  test "a String is not like a superstring" do
    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    Actual:
    "foo"

    Expected:
    "food"

    """, fn -> like?("foo", "food") end
  end

  test "a Regex is like a String when it matches" do
    assert "foo" |> like?(~r/\Afo/)
  end

  test "a Regex is not like a String when it does not match" do
    refute "foo" |> like?(~r/\Aoo/)
  end

  defmodule TestStruct do
    defstruct [:a, :b]
  end

  defmodule FooStruct do
    defstruct [:a, :b]
  end

  test "a Struct is like the same Struct" do
    assert %TestStruct{a: 1} |> like?(%TestStruct{a: 1})
  end

  test "a Struct is like a Struct with a subset of the attributes" do
    assert %TestStruct{a: 1, b: 2} |> like?(%TestStruct{a: 1})
  end

  test "a Struct is not like a Struct with a superset of the attributes" do
    refute %TestStruct{a: 1} |> like?(%TestStruct{a: 1, b: 2})
  end

  test "a Struct is not like a Struct with the same attributes but different struct types" do
    refute %TestStruct{a: 1} |> like?(%FooStruct{a: 1})
  end

  test "fail it" do
    assert %{a: 1} |> like?(%{a: 2})
  end
end
