defmodule LikenTest do
  use ExUnit.Case
  import Liken
  doctest Liken

  test "an Integer is like the same Integer" do
    assert 1 |> must_contain(1)
  end

  test "an Integer is not like another Integer" do
    func = fn -> must_contain(1, 2) end

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

    assert this |> must_contain(that)
  end

  test "a Map is not like a different Map" do
    func = fn-> must_contain(%{a: 1}, %{a: 2}) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not an exact match for Expected value:

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

    assert this |> must_contain(that)
    assert this |> must_contain(blat)
  end

  test "a Map is not like its superset" do
    func = fn-> must_contain(%{a: 1}, %{a: 1, b: 2}) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not an exact match for Expected value:

    At:
    Map[:b]

    Actual:
    nil

    Expected:
    2

    """, func
  end

  test "a Map is not like another Map if their nested structures differ as a subset" do
    func = fn-> must_contain(%{a: %{b: 2, c: 3}}, %{a: %{b: 2}}) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not an exact match for Expected value:

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
    that = %{a: includes?(%{b: 2})}

    assert this |> must_contain(that)
  end

  test "a List is like the same list" do
    actual = [1, 2, 3]
    expected = [1, 2, 3]

    assert actual |> must_contain(expected)
  end

  test "a List is like a subset List" do
    actual = [1, 2, 3, 4, 5]
    expected = [2, 4]

    assert actual |> must_contain(expected)
  end

  test "a List is not like a superset List" do
    func = fn ->
      actual = [1, 2, 3, 4, 5]
      expected = [2, 6]
      actual |> must_contain(expected)
    end

    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    Actual:
    [1, 2, 3, 4, 5]

    Expected:
    [2, 6]

    """, func
  end

  test "a String is like the same String" do
    assert "foo" |> must_contain("foo")
  end

  test "a String is like a substring" do
    assert "foo" |> must_contain("oo")
  end

  test "a String is not like a superstring" do
    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    Actual:
    "foo"

    Expected:
    "food"

    """, fn -> must_contain("foo", "food") end
  end

  test "a Regex is like a String when it matches" do
    assert "foo" |> must_contain(~r/\Afo/)
  end

  test "a Regex is not like a String when it does not match" do
    func = fn -> "foo" |> must_contain(~r/\Aoo/) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    Actual:
    "foo"

    Expected:
    ~r/\\Aoo/

    """, func
  end

  defmodule TestStruct do
    defstruct [:a, :b]
  end

  defmodule FooStruct do
    defstruct [:a, :b]
  end

  test "a Struct is like the same Struct" do
    expected = %TestStruct{a: 1}
    actual   = %TestStruct{a: 1}
    assert actual |> must_contain(expected)
  end

  test "a Struct is like a Struct with a subset of the attributes" do
    actual = %TestStruct{a: 1, b: 2}
    expected = %{a: 1}

    assert actual |> must_contain(TestStruct, expected)
  end

  test "a Struct is not like a Struct with a superset of the attributes" do
    actual = %TestStruct{a: 1}
    expected = %{a: 1, b: 2}

    func = fn -> assert actual |> must_contain(TestStruct, expected) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not an exact match for Expected value:

    At:
    Map[:b]

    Actual:
    nil

    Expected:
    2

    """, func
  end

  test "a Struct is not like a Struct with the same attributes but different struct types" do
    actual = %TestStruct{a: 1}
    expected = %{a: 1, b: 2}

    func = fn -> assert actual |> must_contain(FooStruct, expected) end

    assert_raise ExUnit.AssertionError, """
    Actual value was not like Expected value:

    Actual:
    %LikenTest.TestStruct{a: 1, b: nil}

    Expected:
    %{a: 1, b: 2}

    """, func
  end

  test "the ultimate example" do
    actual = %{
      first: [1, 2, 3, %{us: "us", them: "them"}, 5],
      second: "ignored",
      third: %TestStruct{a: 1, b: 2},
      fourth: [
        %{key1: "111", key2: "222"},
        %{key3: [3,3,3,3], key4: "444"}
      ]
    }
    expected = %{
      first: includes?([1, includes?(%{us: "us"})]),
      third: includes?(TestStruct, %{a: 1}),
      fourth: includes?([
        includes?(%{key2: "222"}),
        includes?(%{key3: includes?([3,3,3,3]), key4: "444"})
      ])
    }

    assert actual |> must_contain(expected)
  end

  @tag :pending
  test "fail it" do
    assert %{a: 1} |> must_contain(%{a: 2})
  end
end
