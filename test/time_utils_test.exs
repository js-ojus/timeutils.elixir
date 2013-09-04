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

  test "days before" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 4 |> days |> before tnow
    assert {{2013, 8, 31}, {10, 37, 45}} == t
  end

  test "days from" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 27 |> days |> from tnow
    assert {{2013, 10, 1}, {10, 37, 45}} == t
  end

  test "weeks before" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 5 |> weeks |> before tnow
    assert {{2013, 7, 31}, {10, 37, 45}} == t
  end

  test "weeks from" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 51 |> weeks |> from tnow
    assert {{2014, 8, 27}, {10, 37, 45}} == t
  end

  test "months before" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 9 |> months |> before tnow
    assert {{2012, 12, 4}, {10, 37, 45}} == t
  end

  test "months from" do
    tnow = {{2013, 9, 4}, {10, 37, 45}}
    t = 4 |> months |> from tnow
    assert {{2014, 1, 4}, {10, 37, 45}} == t
  end

  test "years before" do
    tnow = {{2012, 2, 29}, {10, 37, 45}}
    t = 1 |> years |> before tnow
    assert {{2011, 2, 28}, {10, 37, 45}} == t
  end

  test "years from" do
    tnow = {{2012, 2, 29}, {10, 37, 45}}
    t = 4 |> years |> from tnow
    assert {{2016, 2, 29}, {10, 37, 45}} == t
  end
end
