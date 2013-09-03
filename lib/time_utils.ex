defmodule TimeUtils do

  @moduledoc """
    TimeUtils is a small library that mimics a part of the Rails utilities
    for working with dates and date-times.  Some examples are shown here.

    iex> import TimeUtils
    nil

    iex> now
    {{2013, 9, 3}, {17, 31, 19}}

    iex> tomorrow
    {{2013, 9, 4}, {17, 32, 5}}

    iex> 10 |> minutes |> ago
    {{2013, 9, 3}, {17, 26, 36}}

    iex> 15 |> hours |> from_now
    {{2013, 9, 4}, {8, 38, 6}}

    It handles the number of days according to the involved months.

    iex> 28 |> days |> from_now
    {{2013, 10, 1}, {17, 40, 21}}

    iex> 3 |> days |> ago
    {{2013, 8, 31}, {17, 42, 44}}

    We can give a reference date or time for calculations.

    iex> 2 |> months |> from 3 |> days |> ago
    {{2013, 10, 31}, {17, 47, 40}}

    iex> 4 |> months |> before 2 |> weeks |> from_now
    {{2013, 5, 17}, {17, 48, 54}}

    However, since it does eager checking, calculations resulting in
    February are *not* commutative if the year is a leap year.

    iex> 6 |> months |> before 3 |> years |> from 3 |> days |> ago
    {{2016, 2, 29}, {17, 45, 33}}

    iex> 3 |> years |> from 6 |> months |> before 3 |> days |> ago
    {{2016, 2, 28}, {17, 46, 3}}

    Explicit parentheses could help in cases such as above.  We are more
    likely to have variables in real code, of course, making it look much
    less ambiguous.

    iex> p = 3
    3
    iex> q = 3
    3
    iex> a_date = p |> years |> from q |> days |> ago
    {{2016, 8, 31}, {18, 6, 12}}
    iex> 6 |> months |> before a_date
    {{2016, 2, 29}, {18, 6, 12}}
  """

  @doc "Answers the given number itself, treating it as the number of seconds."
  def seconds(s), do: s

  @doc "Converts the given number of minutes to seconds, and answers it."
  def minutes(m), do: m * 60

  @doc "Converts the given number of hours to seconds, and answers it."
  def hours(h), do: h * 3600

  @doc "Converts the given number of days to seconds, and answers it."
  def days(d), do: d * 86400

  @doc "Converts the given number of weeks to seconds, and answers it."
  def weeks(w), do: w * 604800

  @doc "Answers a tuple with an atom ':months' and the given number of months."
  def months(m), do: {:months, m}

  @doc "Answers a tuple with an atom ':months' and the given number of years converted to months."
  def years(y), do: {:months, y * 12}

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def before({:months, m}, whence) do
    adjust {:months, m}, from: whence
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def before(s, whence) do
    adjust s, from: whence
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def from({:months, m}, whence) do
    adjust {:months, m}, from: whence, future: true
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def from(s, whence) do
    adjust s, from: whence, future: true
  end

  # Forward declaration.
  defp adjust(what, opts // [])

  @doc "Answers `true` if the given year is a leap year; `false` otherwise."
  def is_leap_year?(y) do
    cond do
      0 == rem(y, 400) -> true
      0 == rem(y, 100) -> false
      0 == rem(y, 4) -> true
      true -> false
    end
  end
  
  # This is the internal work-horse function.  The end-point functions
  # utilise this function for the actual calculation.  Apart from
  # performing the requested calculation, this function handles leap
  # years and month-specific number of days.
  defp adjust({:months, m}, opts) do
    {{cy, cm, cd}, tm} = case List.keyfind opts, :from, 0 do
                           {:from, whence} -> case whence do
                                                {d, t} -> {d, t}
                                                d -> {d, :erlang.time}
                                              end
                           _ -> :erlang.localtime
                         end
    ccm = cy * 12 + cm
    cim = case List.keyfind opts, :future, 0 do
            {:future, _} -> ccm + m
            _ -> ccm - m
          end
    iy = div cim, 12
    im = rem cim, 12
    if im == 0 do
      iy = iy - 1
      im = 12
    end
    id = case cd do
           t when t <= 28 -> t
           t when (t >= 29 and im == 2) ->
             if is_leap_year?(iy), do: 29, else: 28
           t when t <= 30 -> t
           t when t == 31 -> if im in [4, 6, 9, 11], do: 30, else: 31
         end
    {{iy, im, id}, tm}
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def ago({:months, m}) do
    adjust {:months, m}
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def from_now({:months, m}) do
    adjust {:months, m}, future: true
  end

  # This is the internal work-horse function.  The end-point functions
  # utilise this function for the actual calculation.  Apart from
  # performing the requested calculation, this function handles leap
  # years and month-specific number of days.
  defp adjust(s, opts) do
    w = case List.keyfind opts, :from, 0 do
          {:from, whence} -> whence
          _ -> :erlang.localtime
        end
    w = :erlang.localtime_to_universaltime w
    utc = :erlang.universaltime_to_posixtime(w)
    utc = case List.keyfind opts, :future, 0 do
            {:future, _} -> utc + s
            _ -> utc - s
          end
    upd = :erlang.posixtime_to_universaltime utc
    :erlang.universaltime_to_localtime upd
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def ago(s) do
    adjust s
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  def from_now(s) do
    adjust s, future: true
  end

  @doc "Answers the current date-time."
  def now, do: :erlang.localtime

  @doc "Answers the current date."
  def today, do: :erlang.date

  @doc "Answers yesterday's date-time."
  def yesterday, do: 1 |> days |> ago

  @doc "Answers tomorrow's date-time."
  def tomorrow, do: 1 |> days |> from_now

  @doc "Answers the date-time of a week ago."
  def last_week, do: 1 |> weeks |> ago

  @doc "Answers the date-time of a week henceforth."
  def next_week, do: 1 |> weeks |> from_now

  @doc "Answers the date-time of a month ago."
  def last_month, do: 1 |> months |> ago

  @doc "Answers the date-time of a month henceforth."
  def next_month, do: 1 |> months |> from_now

  @doc "Answers the date-time of a year ago."
  def last_year, do: 1 |> years |> ago

  @doc "Answers the date-time of a year henceforth."
  def next_year, do: 1 |> years |> from_now

end