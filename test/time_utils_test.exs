defmodule TimeUtilsTest do
  use ExUnit.Case
  import TimeUtils

  test "seconds before" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 15 |> seconds |> before tnow
    assert {{2013, 9, 4}, {10, 37, 30}} == t
  end

  test "seconds from" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 15 |> seconds |> from tnow
    assert {{2013, 9, 4}, {10, 38, 0}} == t
  end

  test "minutes before" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 25 |> minutes |> before tnow
    assert {{2013, 9, 4}, {10, 12, 45}} == t
  end

  test "minutes from" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 25 |> minutes |> from tnow
    assert {{2013, 9, 4}, {11, 2, 45}} == t
  end

  test "hours before" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 11 |> hours |> before tnow
    assert {{2013, 9, 3}, {23, 37, 45}} == t
  end

  test "hours from" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 14 |> hours |> from tnow
    assert {{2013, 9, 5}, {0, 37, 45}} == t
  end
end
